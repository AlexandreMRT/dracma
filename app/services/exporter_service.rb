# frozen_string_literal: true

# Exporter service: CSV, JSON, Markdown reports, and AI reports.
# Ported from Python exporter.py.
module ExporterService
  EXPORTS_PATH = ENV.fetch("EXPORTS_PATH", Rails.root.join("exports").to_s)

  # Fetch the latest quote per asset (or for a specific date).
  def self.latest_quotes(quote_date: nil)
    scope = Quote.includes(:asset)
    if quote_date
      scope.where(quote_date: quote_date)
    else
      scope.where(
        "(asset_id, quote_date) IN (SELECT asset_id, MAX(quote_date) FROM quotes GROUP BY asset_id)"
      )
    end.to_a
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
      atualizado_em: quote.fetched_at&.strftime("%Y-%m-%d %H:%M:%S"),
    }
  end

  # --- CSV export ---
  def self.export_csv(quote_date: nil, filename: nil)
    quotes = latest_quotes(quote_date: quote_date)
    return nil if quotes.empty?

    date_str = (quote_date || Date.current).strftime("%Y-%m-%d")
    filename ||= "cotacoes_#{date_str}.csv"
    filepath = File.join(EXPORTS_PATH, filename)
    FileUtils.mkdir_p(EXPORTS_PATH)

    rows = quotes.map { |q| format_row(q) }.sort_by { |r| [r[:setor], r[:ticker]] }

    require "csv"
    CSV.open(filepath, "w", encoding: "UTF-8") do |csv|
      csv << rows.first.keys
      rows.each { |r| csv << r.values }
    end

    Rails.logger.info("CSV exported: #{filepath} (#{rows.size} records)")
    filepath
  end

  # --- JSON export ---
  def self.export_json(quote_date: nil, filename: nil)
    quotes = latest_quotes(quote_date: quote_date)
    return nil if quotes.empty?

    date_str = (quote_date || Date.current).strftime("%Y-%m-%d")
    filename ||= "cotacoes_#{date_str}.json"
    filepath = File.join(EXPORTS_PATH, filename)
    FileUtils.mkdir_p(EXPORTS_PATH)

    rows = quotes.map { |q| format_row(q) }.sort_by { |r| [r[:setor], r[:ticker]] }

    data = {
      data_exportacao: Time.current.strftime("%Y-%m-%d %H:%M:%S"),
      total_ativos: rows.size,
      cotacoes: rows,
    }

    File.write(filepath, JSON.pretty_generate(data))
    Rails.logger.info("JSON exported: #{filepath} (#{rows.size} records)")
    filepath
  end

  # --- Report data builder ---
  def self.report_data
    quotes = latest_quotes
    return nil if quotes.empty?

    rows = quotes.map { |q| format_row(q) }

    br   = rows.select { |r| r[:tipo] == "stock" }
    us   = rows.select { |r| r[:tipo] == "us_stock" }
    comm = rows.select { |r| r[:tipo] == "commodity" }
    cry  = rows.select { |r| r[:tipo] == "crypto" }
    all  = br + us

    with_1d = all.select { |r| r[:var_1d] }
    gainers = with_1d.sort_by { |r| -(r[:var_1d] || 0) }.first(10)
    losers  = with_1d.sort_by { |r| r[:var_1d] || 0 }.first(10)

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
        volume_spike: vol_spike, golden_cross: golden,
      },
      news_sentiment: { positive: positive_news, negative: negative_news },
      algorithmic: algo,
      all_data: rows,
    }
  end

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

    report = {
      metadata: {
        report_type: "daily_market_summary",
        generated_at: data[:generated_at].iso8601,
        total_assets: data[:total_assets],
        version: "1.0",
      },
      market_context: {
        ibov_ytd_pct: data[:market_context][:ibov_ytd],
        sp500_ytd_pct: data[:market_context][:sp500_ytd],
        usd_brl: data[:market_context][:usd_brl],
        asset_counts: data[:counts],
      },
      signals_summary: {
        bullish_count: data[:signals][:bullish].size,
        bearish_count: data[:signals][:bearish].size,
        bullish_tickers: data[:signals][:bullish].map { |r| r[:ticker] },
        bearish_tickers: data[:signals][:bearish].map { |r| r[:ticker] },
        rsi_oversold: data[:signals][:oversold].map { |r| { ticker: r[:ticker], rsi: r[:rsi_14] } },
        rsi_overbought: data[:signals][:overbought].map { |r| { ticker: r[:ticker], rsi: r[:rsi_14] } },
        near_52w_high: data[:signals][:near_52w_high].map { |r| r[:ticker] },
        near_52w_low: data[:signals][:near_52w_low].map { |r| r[:ticker] },
        volume_spike: data[:signals][:volume_spike].map { |r| r[:ticker] },
        golden_cross_count: data[:signals][:golden_cross].size,
      },
      top_movers: {
        gainers_1d: data[:top_movers][:gainers].first(10).map { |r|
          { ticker: r[:ticker], name: r[:nome], change_1d: r[:var_1d] }
        },
        losers_1d: data[:top_movers][:losers].first(10).map { |r|
          { ticker: r[:ticker], name: r[:nome], change_1d: r[:var_1d] }
        },
      },
      news_sentiment: {
        positive_count: data[:news_sentiment][:positive].size,
        negative_count: data[:news_sentiment][:negative].size,
        positive: data[:news_sentiment][:positive].first(10).map { |r|
          { ticker: r[:ticker], score: r[:news_sentiment_combined],
            headline: (r[:news_headline_pt] || r[:news_headline_en] || "")[0, 100] }
        },
        negative: data[:news_sentiment][:negative].first(10).map { |r|
          { ticker: r[:ticker], score: r[:news_sentiment_combined],
            headline: (r[:news_headline_pt] || r[:news_headline_en] || "")[0, 100] }
        },
      },
      actionable_insights: {
        potential_buys: data[:signals][:oversold].map { |r| r[:ticker] } +
                        data[:signals][:near_52w_low].map { |r| r[:ticker] },
        potential_sells: data[:signals][:overbought].map { |r| r[:ticker] },
        algorithmic_watchlist: data.dig(:algorithmic, :watchlist) || [],
        algorithmic_avoid_list: data.dig(:algorithmic, :avoid_list) || [],
      },
      polymarket_sentiment: polymarket_for_report,
      full_data: data[:all_data],
    }

    File.write(filepath, JSON.pretty_generate(report))
    Rails.logger.info("AI report exported: #{filepath}")
    filepath
  end

  # --- Generate both reports ---
  def self.generate_reports
    human = export_human_report
    ai    = export_ai_report
    [human, ai]
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
        },
      }
    end
    result
  rescue StandardError => e
    { error: e.message }
  end
end
