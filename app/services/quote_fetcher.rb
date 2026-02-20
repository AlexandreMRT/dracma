# frozen_string_literal: true

# Main quote fetching service. Orchestrates Yahoo Finance, news, benchmarks,
# signals, and persists results to the database.
# Ported from Python fetcher.py.
class QuoteFetcher
  def initialize
    @logger = Rails.logger
    @usd_brl = nil
    @benchmarks = {}
  end

  # Fetch and save quotes for all tracked assets.
  def fetch_all
    @logger.info("=== QuoteFetcher: starting full fetch ===")
    start = Time.current

    @usd_brl = fetch_usd_brl
    @benchmarks = fetch_benchmarks
    @logger.info("USD/BRL: #{@usd_brl}")

    catalog = build_asset_list
    @logger.info("Assets to fetch: #{catalog.size}")

    results = []
    errors = 0

    catalog.each do |entry|
      result = fetch_single(entry)
      if result
        results << result
      else
        errors += 1
      end
    end

    # Fetch news for stocks only
    results.select { |r| %w[stock us_stock].include?(r[:asset_type]) }.each do |r|
      fetch_news_for(r)
    end

    # Save to database
    saved = save_all(results)

    elapsed = Time.current - start
    @logger.info("=== QuoteFetcher complete: #{saved}/#{catalog.size} saved in #{elapsed.round(1)}s ===")
    [saved, errors]
  end

  private

  def fetch_usd_brl
    data = YahooFinanceClient.history("USDBRL=X", range: "5d")
    data[:quotes].last&.dig(:close) || 6.20
  rescue StandardError
    6.20
  end

  def fetch_benchmarks
    result = {}
    { "^BVSP" => "ibov", "^GSPC" => "sp500" }.each do |ticker, prefix|
      data = YahooFinanceClient.history(ticker, range: "1y")
      quotes = data[:quotes]
      next if quotes.empty?

      current = quotes.last[:close]
      today = quotes.last[:date]

      result["#{prefix}_change_1d"] = change_pct(current, price_at(quotes, today - 1))
      result["#{prefix}_change_1w"] = change_pct(current, price_at(quotes, today - 7))
      result["#{prefix}_change_1m"] = change_pct(current, price_at(quotes, today - 30))
      result["#{prefix}_change_ytd"] = change_pct(current, price_at(quotes, Date.new(today.year, 1, 1)))
    rescue StandardError => e
      @logger.warn("Benchmark #{ticker} error: #{e.message}")
    end
    result
  end

  def build_asset_list
    list = []
    AssetCatalog::IBOVESPA_STOCKS.each { |t, i| list << { ticker: t, info: i, type: "stock", brazilian: true } }
    AssetCatalog::US_STOCKS.each { |t, i| list << { ticker: t, info: i, type: "us_stock", brazilian: false } }
    AssetCatalog::COMMODITIES.each { |t, i| list << { ticker: t, info: i, type: "commodity", brazilian: false } }
    AssetCatalog::CRYPTO.each { |t, i| list << { ticker: t, info: i, type: "crypto", brazilian: false } }
    AssetCatalog::CURRENCY.each { |t, i| list << { ticker: t, info: i, type: "currency", brazilian: false } }
    list
  end

  def fetch_single(entry)
    ticker = entry[:ticker]
    data = YahooFinanceClient.history(ticker)
    quotes = data[:quotes]
    return nil if quotes.empty?

    latest = quotes.last
    today = latest[:date]
    current = latest[:close]

    # Fundamental data
    fundamentals = YahooFinanceClient.info(ticker)

    # Technical indicators
    technicals = calculate_technicals(quotes, current)

    # % from 52-week high
    w52h = fundamentals[:week_52_high]
    pct_from_52w = w52h && w52h > 0 ? ((current - w52h) / w52h) * 100 : nil

    quote_data = {
      ticker: ticker,
      open: latest[:open],
      high: latest[:high],
      low: latest[:low],
      close: current,
      volume: latest[:volume],
      date: today,
      price_1d: price_at(quotes, today - 1),
      price_1w: price_at(quotes, today - 7),
      price_1m: price_at(quotes, today - 30),
      price_ytd: price_at(quotes, Date.new(today.year, 1, 1)),
      price_5y: price_at(quotes, today - (5 * 365)),
      price_all: quotes.first[:close],
      pct_from_52w_high: pct_from_52w,
    }.merge(fundamentals).merge(technicals)

    # Changes
    %i[1d 1w 1m ytd 5y all].each do |period|
      key = :"price_#{period}"
      key = :price_all if period == :all
      key = :price_ytd if period == :ytd
      quote_data[:"change_#{period}"] = change_pct(current, quote_data[key])
    end

    # Benchmark comparison
    @benchmarks.each { |k, v| quote_data[k.to_sym] = v }
    %w[1d 1m ytd].each do |p|
      chg = quote_data[:"change_#{p}"]
      quote_data[:"vs_ibov_#{p}"] = chg && @benchmarks["ibov_change_#{p}"] ? chg - @benchmarks["ibov_change_#{p}"] : nil
      quote_data[:"vs_sp500_#{p}"] = chg && @benchmarks["sp500_change_#{p}"] ? chg - @benchmarks["sp500_change_#{p}"] : nil
    end

    # Signals
    signals = SignalDetector.detect(quote_data)
    quote_data.merge!(signals.as_db_flags)

    # Price conversion
    case entry[:type]
    when "stock"
      price_brl = current
      price_usd = current / @usd_brl
    when "currency"
      price_brl = current
      price_usd = 1.0
    else
      price_usd = current
      price_brl = current * @usd_brl
    end

    entry.merge(quote_data: quote_data, price_brl: price_brl, price_usd: price_usd)
  rescue StandardError => e
    @logger.error("Error fetching #{entry[:ticker]}: #{e.message}")
    nil
  end

  def fetch_news_for(result)
    return unless result

    news = NewsFetcher.sentiment(
      result[:ticker],
      result.dig(:info, :name) || "",
      brazilian: result[:brazilian]
    )
    result[:quote_data].merge!(news)
  rescue StandardError => e
    @logger.warn("News error for #{result[:ticker]}: #{e.message}")
  end

  def save_all(results)
    saved = 0
    results.each do |r|
      asset = Asset.find_or_create_by!(ticker: r[:ticker]) do |a|
        a.name = r.dig(:info, :name) || "Desconhecido"
        a.sector = r.dig(:info, :sector) || "Outro"
        a.asset_type = normalize_type(r[:type])
        a.unit = r.dig(:info, :unit) || ""
      end

      qd = r[:quote_data]
      quote_date = qd[:date].is_a?(Date) ? qd[:date].to_datetime : qd[:date]

      quote = Quote.find_or_initialize_by(asset: asset, quote_date: quote_date)
      assign_quote_fields(quote, qd, r[:price_brl], r[:price_usd])
      quote.fetched_at = Time.current
      quote.save!
      saved += 1
    rescue StandardError => e
      @logger.error("Save error #{r[:ticker]}: #{e.message}")
    end
    saved
  end

  def normalize_type(type)
    type == "us_stock" ? "stock" : type
  end

  def assign_quote_fields(quote, qd, price_brl, price_usd)
    g = ->(k) { qd[k] }

    quote.price_brl = price_brl
    quote.price_usd = price_usd
    quote.open_price = g.call(:open)
    quote.high_price = g.call(:high)
    quote.low_price = g.call(:low)
    quote.volume = g.call(:volume)

    # Historical changes
    %i[change_1d change_1w change_1m change_ytd change_5y change_all].each { |k| quote.send(:"#{k}=", g.call(k)) }
    quote.price_1d_ago = g.call(:price_1d)
    quote.price_1w_ago = g.call(:price_1w)
    quote.price_1m_ago = g.call(:price_1m)
    quote.price_ytd = g.call(:price_ytd)
    quote.price_5y_ago = g.call(:price_5y)
    quote.price_all_time = g.call(:price_all)

    # Fundamentals
    %i[market_cap pe_ratio forward_pe pb_ratio dividend_yield eps
       beta week_52_high week_52_low pct_from_52w_high
       profit_margin roe debt_to_equity
       analyst_rating target_price num_analysts].each { |k| quote.send(:"#{k}=", g.call(k)) }

    # Technicals
    %i[ma_50 ma_200 rsi_14 above_ma_50 above_ma_200 ma_50_above_200
       volatility_30d avg_volume_20d volume_ratio].each { |k| quote.send(:"#{k}=", g.call(k)) }

    # Benchmarks
    %i[ibov_change_1d ibov_change_1w ibov_change_1m ibov_change_ytd
       sp500_change_1d sp500_change_1w sp500_change_1m sp500_change_ytd
       vs_ibov_1d vs_ibov_1m vs_ibov_ytd
       vs_sp500_1d vs_sp500_1m vs_sp500_ytd].each { |k| quote.send(:"#{k}=", g.call(k)) }

    # Signals
    %i[signal_golden_cross signal_death_cross signal_rsi_oversold signal_rsi_overbought
       signal_52w_high signal_52w_low signal_volume_spike signal_summary].each { |k| quote.send(:"#{k}=", g.call(k)) }

    # News
    %i[news_sentiment_pt news_sentiment_en news_sentiment_combined
       news_count_pt news_count_en news_headline_pt news_headline_en
       news_sentiment_label].each { |k| quote.send(:"#{k}=", g.call(k)) }

    # Polymarket (populated separately if available)
    %i[polymarket_score polymarket_label polymarket_confidence
       polymarket_market_count polymarket_volume
       polymarket_top_question polymarket_top_probability].each do |k|
      quote.send(:"#{k}=", g.call(k)) if g.call(k)
    end
  end

  def calculate_technicals(quotes, current)
    closes = quotes.map { |q| q[:close] }
    result = {}

    if closes.size >= 50
      ma50 = closes.last(50).sum / 50.0
      result[:ma_50] = ma50
      result[:above_ma_50] = current > ma50 ? 1 : 0
    end

    if closes.size >= 200
      ma200 = closes.last(200).sum / 200.0
      result[:ma_200] = ma200
      result[:above_ma_200] = current > ma200 ? 1 : 0
      result[:ma_50_above_200] = result[:ma_50] && result[:ma_50] > ma200 ? 1 : 0 if result[:ma_50]
    end

    # RSI
    if closes.size >= 15
      result[:rsi_14] = calculate_rsi(closes)
    end

    # Volatility
    if closes.size >= 30
      returns = closes.last(31).each_cons(2).map { |a, b| (b - a) / a }
      mean = returns.sum / returns.size
      variance = returns.sum { |r| (r - mean)**2 } / returns.size
      result[:volatility_30d] = Math.sqrt(variance) * 100
    end

    # Volume
    volumes = quotes.map { |q| q[:volume] }.compact
    if volumes.size >= 20
      avg_vol = volumes.last(20).sum / 20.0
      current_vol = volumes.last
      result[:avg_volume_20d] = avg_vol
      result[:volume_ratio] = avg_vol > 0 ? current_vol / avg_vol : nil
    end

    result
  end

  def calculate_rsi(closes, period: 14)
    return nil if closes.size < period + 1

    deltas = closes.last(period + 1).each_cons(2).map { |a, b| b - a }
    gains = deltas.select(&:positive?)
    losses = deltas.select(&:negative?).map(&:abs)

    avg_gain = gains.any? ? gains.sum / period.to_f : 0
    avg_loss = losses.any? ? losses.sum / period.to_f : 0

    return 100.0 if avg_loss.zero?

    rs = avg_gain / avg_loss
    100 - (100 / (1 + rs))
  end

  def price_at(quotes, target_date)
    target_date = target_date.to_date if target_date.respond_to?(:to_date)
    quotes.select { |q| q[:date] <= target_date }.last&.dig(:close)
  end

  def change_pct(current, previous)
    return nil unless previous && previous > 0

    ((current - previous) / previous) * 100
  end
end
