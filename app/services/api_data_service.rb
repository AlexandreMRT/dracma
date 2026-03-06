# frozen_string_literal: true
# typed: true

module ApiDataService
  extend T::Sig

  MOVER_KEYS = T.let({
    "1d" => :var_1d,
    "1w" => :var_1w,
    "1m" => :var_1m,
    "ytd" => :var_ytd,
    "5y" => :var_5y,
    "all" => :var_all
  }.freeze, T::Hash[String, Symbol])
  NEWS_SENTIMENTS = T.let(%w[positive negative neutral].freeze, T::Array[String])

  sig { params(quote_date: T.nilable(Date)).returns(T::Array[T::Hash[Symbol, T.untyped]]) }
  def self.rows(quote_date: nil)
    ExporterService.latest_quotes(quote_date: quote_date)
                   .map { |quote| ExporterService.format_row(quote) }
                   .sort_by { |row| [ row[:setor].to_s, row[:ticker].to_s ] }
  end

  sig { params(identifier: T.untyped, history_limit: Integer).returns(T.nilable(T::Hash[Symbol, T.untyped])) }
  def self.asset_detail(identifier, history_limit: 30)
    asset = find_asset(identifier)
    return nil unless asset

    history_quotes = asset.quotes.order(quote_date: :desc).limit(history_limit).to_a
    latest_quote = history_quotes.first
    latest_row = latest_quote ? ExporterService.format_row(latest_quote) : nil

    {
      asset: asset_payload(asset),
      latest: latest_row,
      signals: latest_row ? signals_payload(latest_row) : {},
      history: history_quotes.map { |quote| history_payload(quote) }
    }
  end

  sig { params(quote_date: T.nilable(Date)).returns(T::Array[T::Hash[Symbol, T.untyped]]) }
  def self.sector_performance(quote_date: nil)
    stock_rows(rows(quote_date: quote_date)).group_by { |row| sector_name_for(row) }.map do |sector, sector_rows|
      {
        sector: sector,
        asset_count: sector_rows.size,
        avg_change_1d: average(sector_rows.filter_map { |row| row[:var_1d]&.to_f }),
        avg_change_1m: average(sector_rows.filter_map { |row| row[:var_1m]&.to_f }),
        avg_change_ytd: average(sector_rows.filter_map { |row| row[:var_ytd]&.to_f }),
        bullish_count: sector_rows.count { |row| row[:signal_summary] == "bullish" },
        bearish_count: sector_rows.count { |row| row[:signal_summary] == "bearish" },
        top_tickers: sector_rows.sort_by { |row| -(row[:var_1d] || -10_000.0) }
                                .first(3)
                                .map { |row| row[:ticker] }
      }
    end.sort_by { |row| [ -(row[:avg_change_1d] || -10_000.0), row[:sector].to_s ] }
  end

  sig { params(period: String).returns(T.nilable(Symbol)) }
  def self.mover_key_for(period)
    MOVER_KEYS[period]
  end

  sig { params(quote_date: T.nilable(Date)).returns(T::Hash[Symbol, T.untyped]) }
  def self.signals_summary(quote_date: nil)
    stocks = stock_rows(rows(quote_date: quote_date))

    {
      bullish: stocks.select { |row| row[:signal_summary] == "bullish" }.map { |row| row[:ticker] },
      bearish: stocks.select { |row| row[:signal_summary] == "bearish" }.map { |row| row[:ticker] },
      rsi_oversold: stocks.select { |row| row[:signal_rsi_oversold] == 1 }
                          .map { |row| { ticker: row[:ticker], rsi: row[:rsi_14] } },
      rsi_overbought: stocks.select { |row| row[:signal_rsi_overbought] == 1 }
                            .map { |row| { ticker: row[:ticker], rsi: row[:rsi_14] } },
      near_52w_high: stocks.select { |row| row[:signal_52w_high] == 1 }.map { |row| row[:ticker] },
      near_52w_low: stocks.select { |row| row[:signal_52w_low] == 1 }.map { |row| row[:ticker] },
      volume_spike: stocks.select { |row| row[:signal_volume_spike] == 1 }.map { |row| row[:ticker] }
    }
  end

  sig { params(period: String, limit: Integer, quote_date: T.nilable(Date)).returns(T::Hash[Symbol, T.untyped]) }
  def self.movers(period:, limit:, quote_date: nil)
    key = T.must(mover_key_for(period))
    candidates = stock_rows(rows(quote_date: quote_date)).select { |row| !row[key].nil? }

    {
      period: period,
      limit: limit,
      gainers: candidates.sort_by { |row| -(row[key] || 0.0) }
                         .first(limit)
                         .map { |row| mover_payload(row, key) },
      losers: candidates.sort_by { |row| row[key] || 0.0 }
                        .first(limit)
                        .map { |row| mover_payload(row, key) }
    }
  end

  sig { params(sentiment: String).returns(T::Boolean) }
  def self.valid_news_sentiment?(sentiment)
    NEWS_SENTIMENTS.include?(sentiment)
  end

  sig { params(sentiment: T.nilable(String), limit: Integer, quote_date: T.nilable(Date)).returns(T::Array[T::Hash[Symbol, T.untyped]]) }
  def self.news_items(sentiment: nil, limit: 50, quote_date: nil)
    items = stock_rows(rows(quote_date: quote_date)).select { |row| !row[:news_sentiment_combined].nil? }
    items = items.select { |row| row[:news_sentiment_label] == sentiment } if sentiment

    sorted = case sentiment
    when "positive"
               items.sort_by { |row| -(row[:news_sentiment_combined] || 0.0) }
    when "negative"
               items.sort_by { |row| row[:news_sentiment_combined] || 0.0 }
    when "neutral"
               items.sort_by { |row| (row[:news_sentiment_combined] || 0.0).abs }
    else
               items.sort_by { |row| -(row[:news_sentiment_combined].to_f.abs) }
    end

    sorted.first(limit).map { |row| news_payload(row) }
  end

  sig { params(asset: T.untyped).returns(T::Hash[Symbol, T.untyped]) }
  def self.asset_payload(asset)
    {
      id: asset.id,
      ticker: asset.ticker.delete_suffix(".SA"),
      source_ticker: asset.ticker,
      name: asset.name,
      sector: asset.sector,
      asset_type: asset.asset_type,
      unit: asset.unit
    }
  end

  sig { params(quote: T.untyped).returns(T::Hash[Symbol, T.untyped]) }
  def self.history_payload(quote)
    {
      date: quote.quote_date&.strftime("%Y-%m-%d"),
      price_brl: quote.price_brl&.round(2),
      price_usd: quote.price_usd&.round(2),
      volume: quote.volume,
      change_1d: quote.change_1d&.round(2),
      signal_summary: quote.signal_summary,
      news_sentiment_combined: quote.news_sentiment_combined&.round(3)
    }
  end

  sig { params(row: T::Hash[Symbol, T.untyped]).returns(T::Hash[Symbol, T.untyped]) }
  def self.signals_payload(row)
    {
      summary: row[:signal_summary],
      rsi_14: row[:rsi_14],
      golden_cross: row[:signal_golden_cross],
      death_cross: row[:signal_death_cross],
      rsi_oversold: row[:signal_rsi_oversold],
      rsi_overbought: row[:signal_rsi_overbought],
      near_52w_high: row[:signal_52w_high],
      near_52w_low: row[:signal_52w_low],
      volume_spike: row[:signal_volume_spike]
    }
  end

  sig { params(row: T::Hash[Symbol, T.untyped], key: Symbol).returns(T::Hash[Symbol, T.untyped]) }
  def self.mover_payload(row, key)
    {
      ticker: row[:ticker],
      nome: row[:nome],
      setor: row[:setor],
      tipo: row[:tipo],
      change: row[key],
      price_brl: row[:preco_brl],
      price_usd: row[:preco_usd],
      signal_summary: row[:signal_summary],
      news_sentiment_label: row[:news_sentiment_label]
    }
  end

  sig { params(row: T::Hash[Symbol, T.untyped]).returns(T::Hash[Symbol, T.untyped]) }
  def self.news_payload(row)
    {
      ticker: row[:ticker],
      nome: row[:nome],
      setor: row[:setor],
      tipo: row[:tipo],
      sentiment_score: row[:news_sentiment_combined],
      sentiment_label: row[:news_sentiment_label],
      headline: row[:news_headline_pt] || row[:news_headline_en],
      headline_pt: row[:news_headline_pt],
      headline_en: row[:news_headline_en],
      news_count_pt: row[:news_count_pt],
      news_count_en: row[:news_count_en],
      signal_summary: row[:signal_summary]
    }
  end

  sig { params(identifier: T.untyped).returns(T.nilable(Asset)) }
  def self.find_asset(identifier)
    normalized = normalized_ticker(identifier)
    brazilian_ticker = normalized.end_with?(".SA") ? nil : "#{normalized}.SA"

    Asset.find_by(id: identifier) ||
      Asset.find_by(ticker: normalized) ||
      (brazilian_ticker ? Asset.find_by(ticker: brazilian_ticker) : nil)
  end

  sig { params(identifier: T.untyped).returns(String) }
  def self.normalized_ticker(identifier)
    identifier.to_s.strip.upcase
  end

  sig { params(row: T::Hash[Symbol, T.untyped]).returns(String) }
  def self.sector_name_for(row)
    sector = row[:setor].to_s.strip
    sector.empty? ? "Other" : sector
  end

  sig { params(rows: T::Array[T::Hash[Symbol, T.untyped]]).returns(T::Array[T::Hash[Symbol, T.untyped]]) }
  def self.stock_rows(rows)
    rows.select { |row| %w[stock us_stock].include?(row[:tipo].to_s) }
  end

  sig { params(values: T::Array[Float]).returns(T.nilable(Float)) }
  def self.average(values)
    return nil if values.empty?

    Float((values.sum / values.size.to_f).round(2))
  end

  private_class_method :asset_payload, :history_payload, :signals_payload, :mover_payload,
    :news_payload, :find_asset, :normalized_ticker, :sector_name_for, :stock_rows, :average
end
