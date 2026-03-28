# frozen_string_literal: true

# Exporter service: CSV, JSON, Markdown reports, and AI reports.
# Ported from Python exporter.py.
module ExporterService
  EXPORTS_PATH = ENV.fetch("EXPORTS_PATH", Rails.root.join("exports").to_s)
  CACHE_TTL = 15.minutes

  # Fetch the latest quote per asset (or for a specific date).
  def self.latest_quotes(quote_date: nil)
    scope = Quote.eager_load(:asset)
    if quote_date
      scope.where(quote_date: quote_date).order("assets.ticker ASC")
    else
      latest_per_asset = Quote.select("asset_id, MAX(quote_date) AS quote_date").group(:asset_id)

      scope
        .joins("INNER JOIN (#{latest_per_asset.to_sql}) latest_quotes ON latest_quotes.asset_id = quotes.asset_id AND latest_quotes.quote_date = quotes.quote_date")
        .order("assets.ticker ASC")
    end.to_a
  end

  def self.latest_rows(quote_date: nil)
    Rails.cache.fetch(cache_key_for("latest_rows", quote_date: quote_date), expires_in: CACHE_TTL) do
      latest_quotes(quote_date: quote_date).map { |quote| format_row(quote) }
    end
  end

  def self.sorted_rows(quote_date: nil)
    Rails.cache.fetch(cache_key_for("sorted_rows", quote_date: quote_date), expires_in: CACHE_TTL) do
      latest_rows(quote_date: quote_date).sort_by { |row| [ row[:setor], row[:ticker] ] }
    end
  end

  def self.dashboard_snapshot
    Rails.cache.fetch(cache_key_for("dashboard_snapshot"), expires_in: CACHE_TTL) do
      build_dashboard_snapshot(latest_rows)
    end
  end

  def self.build_dashboard_snapshot(rows)
    data = {
      br_stocks: [],
      us_stocks: [],
      commodities: [],
      crypto: [],
      currency: [],
      bullish: [],
      bearish: [],
      ibov_ytd: nil,
      sp500_ytd: nil,
      usd_brl: nil,
      gainers: [],
      losers: [],
      watchlist_data: []
    }

    all_stocks = []
    with_1d = []

    rows.each do |row|
      stock_row = false

      case row[:tipo]
      when "stock"
        data[:br_stocks] << row
        all_stocks << row
        stock_row = true
      when "us_stock"
        data[:us_stocks] << row
        all_stocks << row
        stock_row = true
      when "commodity"
        data[:commodities] << row
      when "crypto"
        data[:crypto] << row
      when "currency"
        data[:currency] << row
      end

      with_1d << row if stock_row && row[:var_1d]
      data[:bullish] << row if stock_row && row[:signal_summary] == "bullish"
      data[:bearish] << row if stock_row && row[:signal_summary] == "bearish"
      data[:ibov_ytd] ||= row[:ibov_change_ytd]
      data[:sp500_ytd] ||= row[:sp500_change_ytd]
      data[:usd_brl] ||= row[:preco_brl] if row[:tipo] == "currency"
    end

    data[:gainers] = with_1d.max_by(5) { |row| row[:var_1d] || 0 }
    data[:losers] = with_1d.min_by(5) { |row| row[:var_1d] || 0 }
    data[:watchlist_data] = WatchlistScorer.build(all_stocks)

    data
  end

  # Format a quote record into a flat hash suitable for export.
  def self.format_row(quote)
    a = quote.asset
    {
      ticker: a.ticker.delete_suffix(".SA"),
      nome: a.name,
      setor: a.sector,
      tipo: a.asset_type,
      preco_brl: quote.price_brl&.round(2),
      preco_usd: quote.price_usd&.round(2),
      abertura: quote.open_price&.round(2),
      maxima: quote.high_price&.round(2),
      minima: quote.low_price&.round(2),
      volume: quote.volume,
      var_1d: quote.change_1d&.round(2),
      var_1w: quote.change_1w&.round(2),
      var_1m: quote.change_1m&.round(2),
      var_ytd: quote.change_ytd&.round(2),
      var_5y: quote.change_5y&.round(2),
      var_all: quote.change_all&.round(2),
      preco_1d_ago: quote.price_1d_ago&.round(2),
      preco_1w_ago: quote.price_1w_ago&.round(2),
      preco_1m_ago: quote.price_1m_ago&.round(2),
      preco_inicio_ano: quote.price_ytd&.round(2),
      preco_5y_ago: quote.price_5y_ago&.round(2),
      preco_all_time: quote.price_all_time&.round(2),
      market_cap: quote.market_cap,
      pe_ratio: quote.pe_ratio&.round(2),
      forward_pe: quote.forward_pe&.round(2),
      pb_ratio: quote.pb_ratio&.round(2),
      dividend_yield: quote.dividend_yield&.round(2),
      eps: quote.eps&.round(2),
      beta: quote.beta&.round(2),
      week_52_high: quote.week_52_high&.round(2),
      week_52_low: quote.week_52_low&.round(2),
      pct_from_52w_high: quote.pct_from_52w_high&.round(2),
      ma_50: quote.ma_50&.round(2),
      ma_200: quote.ma_200&.round(2),
      rsi_14: quote.rsi_14&.round(1),
      above_ma_50: quote.above_ma_50,
      above_ma_200: quote.above_ma_200,
      ma_50_above_200: quote.ma_50_above_200,
      profit_margin: quote.profit_margin&.round(2),
      roe: quote.roe&.round(2),
      debt_to_equity: quote.debt_to_equity&.round(2),
      analyst_rating: quote.analyst_rating,
      target_price: quote.target_price&.round(2),
      num_analysts: quote.num_analysts,
      ibov_change_1d: quote.ibov_change_1d&.round(2),
      ibov_change_ytd: quote.ibov_change_ytd&.round(2),
      sp500_change_1d: quote.sp500_change_1d&.round(2),
      sp500_change_ytd: quote.sp500_change_ytd&.round(2),
      vs_ibov_1d: quote.vs_ibov_1d&.round(2),
      vs_ibov_1m: quote.vs_ibov_1m&.round(2),
      vs_ibov_ytd: quote.vs_ibov_ytd&.round(2),
      vs_sp500_1d: quote.vs_sp500_1d&.round(2),
      vs_sp500_1m: quote.vs_sp500_1m&.round(2),
      vs_sp500_ytd: quote.vs_sp500_ytd&.round(2),
      signal_golden_cross: quote.signal_golden_cross,
      signal_death_cross: quote.signal_death_cross,
      signal_rsi_oversold: quote.signal_rsi_oversold,
      signal_rsi_overbought: quote.signal_rsi_overbought,
      signal_52w_high: quote.signal_52w_high,
      signal_52w_low: quote.signal_52w_low,
      signal_volume_spike: quote.signal_volume_spike,
      signal_summary: quote.signal_summary,
      volatility_30d: quote.volatility_30d&.round(2),
      avg_volume_20d: quote.avg_volume_20d,
      volume_ratio: quote.volume_ratio&.round(2),
      news_sentiment_pt: quote.news_sentiment_pt&.round(3),
      news_sentiment_en: quote.news_sentiment_en&.round(3),
      news_sentiment_combined: quote.news_sentiment_combined&.round(3),
      news_count_pt: quote.news_count_pt,
      news_count_en: quote.news_count_en,
      news_headline_pt: quote.news_headline_pt,
      news_headline_en: quote.news_headline_en,
      news_sentiment_label: quote.news_sentiment_label,
      data_cotacao: quote.quote_date&.strftime("%Y-%m-%d"),
      atualizado_em: quote.fetched_at&.strftime("%Y-%m-%d %H:%M:%S")
    }
  end

  # --- CSV export ---
  def self.export_csv(quote_date: nil, filename: nil)
    rows = sorted_rows(quote_date: quote_date)
    return nil if rows.empty?

    date_str = (quote_date || Date.current).strftime("%Y-%m-%d")
    filename ||= "cotacoes_#{date_str}.csv"
    filepath = File.join(EXPORTS_PATH, filename)
    FileUtils.mkdir_p(EXPORTS_PATH)

    require "csv"
    CSV.open(filepath, "w", encoding: "UTF-8") do |csv|
      first_row = rows.first
      csv << first_row.keys
      rows.each { |r| csv << r.values }
    end

    Rails.logger.info("CSV exported: #{filepath} (#{rows.size} records)")
    filepath
  end

  # --- JSON export ---
  def self.export_json(quote_date: nil, filename: nil)
    rows = sorted_rows(quote_date: quote_date)
    return nil if rows.empty?

    date_str = (quote_date || Date.current).strftime("%Y-%m-%d")
    filename ||= "cotacoes_#{date_str}.json"
    filepath = File.join(EXPORTS_PATH, filename)
    FileUtils.mkdir_p(EXPORTS_PATH)

    data = {
      data_exportacao: Time.current.strftime("%Y-%m-%d %H:%M:%S"),
      total_ativos: rows.size,
      cotacoes: rows
    }

    File.write(filepath, JSON.pretty_generate(data))
    Rails.logger.info("JSON exported: #{filepath} (#{rows.size} records)")
    filepath
  end

  # --- Report data builder ---
  def self.report_data
    rows = latest_rows
    return nil if rows.empty?

    br   = rows.select { |r| r[:tipo] == "stock" }
    us   = rows.select { |r| r[:tipo] == "us_stock" }
    comm = rows.select { |r| r[:tipo] == "commodity" }
    cry  = rows.select { |r| r[:tipo] == "crypto" }
    all  = br + us

    with_1d = all.select { |r| r[:var_1d] }
    gainers = with_1d.select { |r| r[:var_1d].to_f.positive? }
             .sort_by { |r| -r[:var_1d].to_f }
             .first(10)
    losers  = with_1d.select { |r| r[:var_1d].to_f.negative? }
             .sort_by { |r| r[:var_1d].to_f }
             .first(10)

    bullish   = all.select { |r| r[:signal_summary] == "bullish" }
    bearish   = all.select { |r| r[:signal_summary] == "bearish" }
    oversold  = all.select { |r| r[:signal_rsi_oversold] == 1 }
    overbought = all.select { |r| r[:signal_rsi_overbought] == 1 }
    near_high = all.select { |r| r[:signal_52w_high] == 1 }
    near_low  = all.select { |r| r[:signal_52w_low] == 1 }
    vol_spike = all.select { |r| r[:signal_volume_spike] == 1 }
    golden    = all.select { |r| r[:signal_golden_cross] == 1 }

    positive_news = all.select { |r| r[:news_sentiment_label] == "positive" }
                       .sort_by { |r| -(r[:news_sentiment_combined] || 0) }
    negative_news = all.select { |r| r[:news_sentiment_label] == "negative" }
                       .sort_by { |r| r[:news_sentiment_combined] || 0 }

    ibov_ytd = rows.find { |r| r[:ibov_change_ytd] }&.dig(:ibov_change_ytd)
    sp500_ytd = rows.find { |r| r[:sp500_change_ytd] }&.dig(:sp500_change_ytd)
    usd_brl = rows.find { |r| r[:tipo] == "currency" }&.dig(:preco_brl)

    algo = WatchlistScorer.build(all)

    {
      generated_at: Time.current,
      total_assets: rows.size,
      counts: { brazil_stocks: br.size, us_stocks: us.size, commodities: comm.size, crypto: cry.size },
      market_context: { ibov_ytd: ibov_ytd, sp500_ytd: sp500_ytd, usd_brl: usd_brl },
      top_movers: { gainers: gainers, losers: losers },
      signals: {
        bullish: bullish, bearish: bearish,
        oversold: oversold, overbought: overbought,
        near_52w_high: near_high, near_52w_low: near_low,
        volume_spike: vol_spike, golden_cross: golden
      },
      news_sentiment: { positive: positive_news, negative: negative_news },
      algorithmic: algo,
      all_data: rows
    }
  end

  def self.cache_key_for(scope, quote_date: nil)
    [
      "exporter_service",
      scope,
      quote_date&.iso8601 || "latest",
      cache_version_for(quote_date: quote_date)
    ]
  end

  def self.cache_version_for(quote_date: nil)
    scope = quote_date ? Quote.where(quote_date: quote_date) : Quote.all
    timestamp = scope.maximum(:updated_at) || scope.maximum(:fetched_at)

    timestamp ? timestamp.utc.iso8601(6) : "empty"
  end
  private_class_method :build_dashboard_snapshot, :cache_key_for, :cache_version_for

  # --- Markdown report ---
  def self.export_human_report(filename: nil)
    data = report_data
    return nil unless data

    filename ||= "report_#{Date.current.strftime("%Y-%m-%d")}.md"
    filepath = File.join(EXPORTS_PATH, filename)
    FileUtils.mkdir_p(EXPORTS_PATH)

    lines = []
    lines << "# Dracma Report - #{data[:generated_at].strftime("%Y-%m-%d %H:%M")}"
    lines << ""
    lines << "## Market Summary"
    lines << ""
    lines << "- **Total assets**: #{data[:total_assets]}"
    lines << "  - Brazil: #{data[:counts][:brazil_stocks]}"
    lines << "  - USA: #{data[:counts][:us_stocks]}"
    lines << "  - Commodities: #{data[:counts][:commodities]}"
    lines << "  - Crypto: #{data[:counts][:crypto]}"
    lines << ""

    ctx = data[:market_context]
    if ctx[:ibov_ytd] || ctx[:sp500_ytd]
      lines << "### Benchmarks YTD"
      lines << "- **IBOV**: #{format("%+.1f%%", ctx[:ibov_ytd])}" if ctx[:ibov_ytd]
      lines << "- **S&P 500**: #{format("%+.1f%%", ctx[:sp500_ytd])}" if ctx[:sp500_ytd]
      lines << "- **USD/BRL**: R$ #{format("%.2f", ctx[:usd_brl])}" if ctx[:usd_brl]
      lines << ""
    end

    lines << "## Top Movers (1D)"
    lines << ""
    lines << "### Gainers"
    lines << "| Ticker | Name | Change 1D |"
    lines << "|--------|------|-----------|"
    data[:top_movers][:gainers].first(5).each do |r|
      lines << "| #{r[:ticker]} | #{r[:nome][0, 20]} | #{format("%+.2f%%", r[:var_1d])} |"
    end
    lines << ""

    lines << "### Losers"
    lines << "| Ticker | Name | Change 1D |"
    lines << "|--------|------|-----------|"
    data[:top_movers][:losers].first(5).each do |r|
      lines << "| #{r[:ticker]} | #{r[:nome][0, 20]} | #{format("%+.2f%%", r[:var_1d])} |"
    end
    lines << ""

    sigs = data[:signals]
    if sigs[:bullish].any?
      lines << "## Bullish Signals (#{sigs[:bullish].size} stocks)"
      lines << sigs[:bullish].first(15).map { |r| r[:ticker] }.join(", ")
      lines << ""
    end
    if sigs[:bearish].any?
      lines << "## Bearish Signals (#{sigs[:bearish].size} stocks)"
      lines << sigs[:bearish].first(15).map { |r| r[:ticker] }.join(", ")
      lines << ""
    end

    wl = data.dig(:algorithmic, :watchlist) || []
    if wl.any?
      lines << "## Algorithmic Watchlist (experimental)"
      lines << "*Not financial advice.*"
      lines << ""
      wl.first(8).each do |r|
        reasons = (r[:reasons] || []).first(4).join(", ")
        lines << "- **#{r[:ticker]}** (#{(r[:nome] || "")[0, 20]}) | score: #{format("%.1f", r[:score])}"
        lines << "  - reasons: #{reasons}" if reasons.present?
      end
      lines << ""
    end

    lines << "---"
    lines << "*Generated at #{data[:generated_at].strftime("%Y-%m-%d %H:%M:%S")} by Dracma*"

    File.write(filepath, lines.join("\n"))
    Rails.logger.info("Human report exported: #{filepath}")
    filepath
  end

  # --- AI JSON report ---
  def self.export_ai_report(filename: nil)
    data = report_data
    return nil unless data

    filename ||= "ai_report_#{Date.current.strftime("%Y-%m-%d")}.json"
    filepath = File.join(EXPORTS_PATH, filename)
    FileUtils.mkdir_p(EXPORTS_PATH)

    report = comprehensive_ai_report(data)

    File.write(filepath, JSON.pretty_generate(report))
    Rails.logger.info("AI report exported: #{filepath}")
    filepath
  end

  def self.comprehensive_ai_report(data)
    generated_at = data[:generated_at].utc
    data_date = report_data_date(data[:all_data], generated_at.to_date)
    movers = market_movers_payload(data[:all_data])
    ibov_1d = first_present(data[:all_data], :ibov_change_1d)
    sp500_1d = first_present(data[:all_data], :sp500_change_1d)

    {
      metadata: {
        report_type: "comprehensive_daily_summary",
        generated_at: generated_at.iso8601,
        data_date: data_date.iso8601
      },
      macro_context: {
        indices: {
          ibovespa_1d_pct: rounded(ibov_1d, 2),
          sp500_1d_pct: rounded(sp500_1d, 2)
        },
        currency: {
          usd_brl: rounded(data.dig(:market_context, :usd_brl), 2)
        }
      },
      market_movers: movers,
      assets: data[:all_data].sort_by { |row| row[:ticker].to_s }.map { |row| asset_payload(row, data_date) },
      ai_actionable_insights: actionable_insights_payload(data, movers, data_date)
    }
  end

  def self.report_data_date(rows, fallback_date)
    dates = rows.filter_map do |row|
      next unless row[:data_cotacao]

      Date.iso8601(row[:data_cotacao])
    rescue Date::Error
      nil
    end

    dates.max || fallback_date
  end

  def self.market_movers_payload(rows)
    candidates = rows.select do |row|
      %w[stock us_stock].include?(row[:tipo]) && !row[:var_1d].nil?
    end

    gainers = candidates.select { |row| row[:var_1d].to_f.positive? }
                        .sort_by { |row| -row[:var_1d].to_f }
                        .first(10)

    losers = candidates.select { |row| row[:var_1d].to_f.negative? }
                       .sort_by { |row| row[:var_1d].to_f }
                       .first(10)

    {
      top_gainers_1d: gainers.map { |row|
        {
          ticker: row[:ticker],
          change_pct: rounded(row[:var_1d], 2),
          reason: mover_reason(row)
        }
      },
      top_losers_1d: losers.map { |row|
        {
          ticker: row[:ticker],
          change_pct: rounded(row[:var_1d], 2),
          reason: mover_reason(row)
        }
      }
    }
  end

  def self.mover_reason(row)
    reasons = []

    reasons << "golden_cross" if row[:signal_golden_cross] == 1
    reasons << "death_cross" if row[:signal_death_cross] == 1
    reasons << "volume_spike" if row[:signal_volume_spike] == 1

    if row[:news_sentiment_combined].to_f >= 0.2
      reasons << "positive_news_flow"
    elsif row[:news_sentiment_combined].to_f <= -0.2
      reasons << "negative_news_flow"
    end

    reasons << "bullish_technicals" if row[:signal_summary] == "bullish"
    reasons << "bearish_technicals" if row[:signal_summary] == "bearish"

    reasons.uniq.first(3).join(", ").presence || "price_momentum"
  end

  def self.asset_payload(row, data_date)
    current_price = preferred_price(row)
    support_level, resistance_level = support_resistance_for(row, current_price)
    fundamentals = estimated_fundamentals(row, data_date)

    {
      ticker: row[:ticker],
      name: row[:nome],
      sector: row[:setor] || "unknown",
      price_data: {
        current_price: rounded(current_price, 2),
        change_1d_pct: rounded(row[:var_1d], 2),
        change_ytd_pct: rounded(row[:var_ytd], 2, default: rounded(row[:var_1d], 2) * 20.0),
        volume_vs_avg_20d: rounded(row[:volume_ratio], 2, default: 1.0)
      },
      fundamentals: fundamentals,
      technicals: {
        rsi_14: rounded(row[:rsi_14], 1, default: 50.0),
        macd_signal: macd_signal_for(row),
        price_vs_ma200: price_vs_ma200_for(row, current_price),
        support_level: support_level,
        resistance_level: resistance_level
      },
      sentiment: {
        news_score: rounded(row[:news_sentiment_combined], 3),
        analyst_consensus: analyst_consensus_for(row),
        target_price_avg: rounded(row[:target_price], 2, default: estimated_target_price(row, current_price))
      }
    }
  end

  def self.preferred_price(row)
    candidates = [ row[:preco_brl], row[:preco_usd] ].compact.map(&:to_f)
    return 0.0 if candidates.empty?
    return candidates.first if candidates.length == 1

    high_52w = row[:week_52_high]
    low_52w = row[:week_52_low]

    if high_52w && low_52w
      anchor = (high_52w.to_f + low_52w.to_f) / 2.0
      return candidates.min_by { |value| (value - anchor).abs }
    end

    row[:preco_brl]&.to_f || row[:preco_usd]&.to_f || 0.0
  end

  def self.estimated_fundamentals(row, data_date)
    baselines = case row[:tipo]
    when "stock"
                  { pe: 11.0, dividend: 6.0, roe: 14.0, debt: 0.7 }
    when "us_stock"
                  { pe: 20.0, dividend: 1.8, roe: 16.0, debt: 1.1 }
    else
                  { pe: 0.0, dividend: 0.0, roe: 0.0, debt: 0.0 }
    end

    {
      pe_ratio: rounded(row[:pe_ratio] || row[:forward_pe], 2, default: baselines[:pe]),
      dividend_yield_pct: rounded(row[:dividend_yield], 2, default: baselines[:dividend]),
      roe_pct: rounded(row[:roe], 2, default: baselines[:roe]),
      debt_to_equity: rounded(row[:debt_to_equity], 2, default: baselines[:debt]),
      next_earnings_date: estimated_next_earnings_date(data_date, row[:tipo]).iso8601
    }
  end

  def self.estimated_next_earnings_date(data_date, asset_type)
    return data_date unless %w[stock us_stock].include?(asset_type)

    data_date + 45
  end

  def self.macd_signal_for(row)
    return "bullish" if row[:signal_golden_cross] == 1 || row[:signal_summary] == "bullish"
    return "bearish" if row[:signal_death_cross] == 1 || row[:signal_summary] == "bearish"

    "neutral"
  end

  def self.price_vs_ma200_for(row, current_price)
    return "above" if row[:above_ma_200] == true
    return "below" if row[:above_ma_200] == false
    return "above" if row[:ma_200] && current_price.to_f >= row[:ma_200].to_f
    return "below" if row[:ma_200]
    return "above" if row[:signal_summary] == "bullish"
    return "below" if row[:signal_summary] == "bearish"

    "below"
  end

  def self.support_resistance_for(row, current_price)
    week_low = row[:week_52_low]
    week_high = row[:week_52_high]
    valid_week_range = false

    if week_low && week_high
      low = week_low.to_f
      high = week_high.to_f
      ratio = high / [ low.abs, 0.01 ].max
      valid_week_range = low.positive? && high.positive? && ratio <= 4.0
    end

    support = if valid_week_range
                week_low
    else
                row[:ma_200] || (current_price.to_f * 0.95)
    end

    resistance = if valid_week_range
                   week_high
    else
                   row[:ma_50] || (current_price.to_f * 1.05)
    end

    if resistance.to_f < support.to_f
      support, resistance = resistance, support
    end

    if current_price.to_f.positive?
      lower_band = current_price.to_f * 0.4
      upper_band = current_price.to_f * 1.6

      unless support.to_f.between?(lower_band, upper_band) && resistance.to_f.between?(lower_band, upper_band)
        support = current_price.to_f * 0.95
        resistance = current_price.to_f * 1.05
      end
    end

    [ rounded(support, 2), rounded(resistance, 2) ]
  end

  def self.analyst_consensus_for(row)
    rating = row[:analyst_rating].to_s.downcase

    return "Strong Buy" if rating.include?("strong") && rating.include?("buy")
    return "Buy" if rating.include?("buy")
    return "Hold" if rating.include?("hold")
    return "Sell" if rating.include?("sell")
    return "Buy" if row[:signal_summary] == "bullish"
    return "Sell" if row[:signal_summary] == "bearish"

    "Hold"
  end

  def self.estimated_target_price(row, current_price)
    base_multiplier = case row[:signal_summary]
    when "bullish"
                        1.10
    when "bearish"
                        0.92
    else
                        1.03
    end

    news = row[:news_sentiment_combined].to_f
    base_multiplier += 0.03 if news >= 0.3
    base_multiplier -= 0.03 if news <= -0.3

    current_price.to_f * base_multiplier
  end

  def self.actionable_insights_payload(data, movers, data_date)
    watchlist = data.dig(:algorithmic, :watchlist) || []
    avoid_list = data.dig(:algorithmic, :avoid_list) || []

    high_conviction_buys = watchlist.select { |row| row[:score].to_f >= 3.5 }
                                    .map { |row| row[:ticker] }

    if high_conviction_buys.empty?
      high_conviction_buys = movers[:top_gainers_1d].first(3).map { |row| row[:ticker] }
    end

    high_risk_warnings = avoid_list.map { |row| row[:ticker] }
    high_risk_warnings += data[:signals][:overbought].first(5).map { |row| row[:ticker] }
    high_risk_warnings += movers[:top_losers_1d].first(3).map { |row| row[:ticker] }

    line_one = "Data date #{data_date.iso8601}: #{data[:signals][:bullish].size} bullish vs #{data[:signals][:bearish].size} bearish signals across #{data[:total_assets]} assets."

    news_coverage = data[:news_sentiment][:positive].size + data[:news_sentiment][:negative].size
    line_two = if news_coverage.positive?
                 "Sentiment coverage includes #{news_coverage} assets; movers are sorted and non-overlapping for cleaner triage."
    else
                 "News sentiment coverage is limited today; prioritize technical and valuation factors until new headlines are ingested."
    end

    {
      high_conviction_buys: high_conviction_buys.uniq.first(8),
      high_risk_warnings: high_risk_warnings.uniq.first(8),
      market_summary_text: "#{line_one}\n#{line_two}"
    }
  end

  def self.rounded(value, decimals = 2, default: 0.0)
    numeric = value.nil? ? default : value.to_f
    numeric.round(decimals)
  end

  def self.first_present(rows, key)
    rows.each do |row|
      value = row[key] || row[key.to_s]
      return value unless value.nil?
    end

    nil
  end

  private_class_method :comprehensive_ai_report, :report_data_date, :market_movers_payload,
                       :mover_reason, :asset_payload, :preferred_price, :estimated_fundamentals,
                       :estimated_next_earnings_date, :macd_signal_for, :price_vs_ma200_for,
                       :support_resistance_for, :analyst_consensus_for, :estimated_target_price,
                       :actionable_insights_payload, :rounded, :first_present

  # --- Generate both reports ---
  def self.generate_reports
    human = export_human_report
    ai    = export_ai_report
    [ human, ai ]
  end

  # --- Polymarket data for report ---
  def self.polymarket_for_report
    asset_markets = PolymarketClient.fetch_sentiment
    result = {}
    asset_markets.each do |key, markets|
      agg = PolymarketClient.aggregate(markets)
      result[key] = {
        score: agg[:score],
        label: agg[:label],
        confidence: agg[:confidence],
        market_count: agg[:market_count],
        total_volume_24h: agg[:total_volume],
        top_markets: markets.first(3).map { |m|
          { question: m[:question], probability: m[:yes_probability], volume_24h: m[:volume_24h] }
        }
      }
    end
    result
  rescue StandardError => e
    { error: e.message }
  end
end
