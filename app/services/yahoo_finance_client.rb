# frozen_string_literal: true
# typed: true

require "net/http"
require "json"
require "uri"

# Yahoo Finance client using public chart API (no gem dependency).
# Replaces Python's yfinance library with pure Net::HTTP calls.
class YahooFinanceClient
  extend T::Sig

  BASE = "https://query1.finance.yahoo.com"

  class Error < StandardError; end

  # Fetch historical OHLCV data for a ticker.
  #
  # @param ticker [String] e.g. "PETR4.SA", "AAPL"
  # @param range [String] "1d","5d","1mo","3mo","6mo","1y","5y","max"
  # @param interval [String] "1d","1wk","1mo"
  # @return [Hash] with :meta and :quotes keys
  sig { params(ticker: String, range: String, interval: String).returns(T::Hash[Symbol, T.untyped]) }
  def self.history(ticker, range: "max", interval: "1d")
    uri = URI("#{BASE}/v8/finance/chart/#{ERB::Util.url_encode(ticker)}")
    uri.query = URI.encode_www_form(range: range, interval: interval, events: "history")

    response = Net::HTTP.get_response(uri)
    raise Error, "Yahoo Finance HTTP #{response.code}" unless response.is_a?(Net::HTTPSuccess)

    data = JSON.parse(response.body)
    result = data.dig("chart", "result", 0)
    raise Error, "No data for #{ticker}" unless result

    meta = result["meta"] || {}
    timestamps = result.dig("timestamp") || []
    ohlcv = result.dig("indicators", "quote", 0) || {}

    quotes = timestamps.each_with_index.map do |ts, i|
      {
        date: Time.at(ts).utc.to_date,
        open: ohlcv.dig("open", i)&.to_f,
        high: ohlcv.dig("high", i)&.to_f,
        low: ohlcv.dig("low", i)&.to_f,
        close: ohlcv.dig("close", i)&.to_f,
        volume: ohlcv.dig("volume", i)&.to_f
      }
    end.reject { |q| q[:close].nil? }

    { meta: meta, quotes: quotes }
  end

  # Fetch fundamental / info data from quoteSummary.
  #
  # @param ticker [String]
  # @return [Hash] key fundamental fields
  sig { params(ticker: String).returns(T::Hash[Symbol, T.untyped]) }
  def self.info(ticker)
    modules = "summaryDetail,defaultKeyStatistics,financialData,recommendationTrend"
    uri = URI("#{BASE}/v10/finance/quoteSummary/#{ERB::Util.url_encode(ticker)}")
    uri.query = URI.encode_www_form(modules: modules)

    response = Net::HTTP.get_response(uri)
    return {} unless response.is_a?(Net::HTTPSuccess)

    data = JSON.parse(response.body)
    result = data.dig("quoteSummary", "result", 0) || {}
    summary = result["summaryDetail"] || {}
    stats = result["defaultKeyStatistics"] || {}
    financials = result["financialData"] || {}

    {
      market_cap: raw_value(summary, "marketCap"),
      pe_ratio: raw_value(summary, "trailingPE"),
      forward_pe: raw_value(stats, "forwardPE"),
      pb_ratio: raw_value(summary, "priceToBook"),
      dividend_yield: safe_pct(summary, "dividendYield"),
      eps: raw_value(stats, "trailingEps"),
      beta: raw_value(stats, "beta"),
      week_52_high: raw_value(summary, "fiftyTwoWeekHigh"),
      week_52_low: raw_value(summary, "fiftyTwoWeekLow"),
      profit_margin: safe_pct(financials, "profitMargins"),
      roe: safe_pct(financials, "returnOnEquity"),
      debt_to_equity: raw_value(financials, "debtToEquity"),
      analyst_rating: raw_value(financials, "recommendationKey"),
      target_price: raw_value(financials, "targetMeanPrice"),
      num_analysts: raw_value(financials, "numberOfAnalystOpinions")
    }
  rescue StandardError
    {}
  end

  def self.raw_value(hash, key)
    hash.dig(key, "raw")
  end

  def self.safe_pct(hash, key)
    val = raw_value(hash, key)
    return nil if val.nil?
    val < 1 ? val * 100 : val
  end

  private_class_method :raw_value, :safe_pct
end
