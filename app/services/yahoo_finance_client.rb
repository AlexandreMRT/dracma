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
  MAX_RETRIES = 5
  BASE_BACKOFF_SECONDS = 1.0
  DEFAULT_THROTTLE_SECONDS = 0.15

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

    response = perform_request(uri)
    raise Error, "Yahoo Finance HTTP #{response.code}" unless response.is_a?(Net::HTTPSuccess)

    data = JSON.parse(T.must(response.body))
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

    response = perform_request(uri)
    return {} unless response.is_a?(Net::HTTPSuccess)

    data = JSON.parse(T.must(response.body))
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

  sig { params(uri: URI::Generic).returns(Net::HTTPResponse) }
  def self.perform_request(uri)
    retries = 0

    loop do
      request = Net::HTTP::Get.new(uri)
      request["User-Agent"] = "Mozilla/5.0 (compatible; DracmaBot/1.0)"

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = 10
      http.read_timeout = 20

      begin
        response = http.request(request)

        if should_retry?(response) && retries < MAX_RETRIES
          retries += 1
          sleep(backoff_for(retries, response))
          next
        end

        sleep(DEFAULT_THROTTLE_SECONDS)
        return response
      rescue Net::OpenTimeout, Net::ReadTimeout, Errno::ECONNRESET, Errno::ETIMEDOUT => e
        if retries < MAX_RETRIES
          retries += 1
          sleep(backoff_for(retries, nil))
          next
        end

        raise Error, "Yahoo Finance request failed: #{e.class}"
      end
    end
  end

  sig { params(response: Net::HTTPResponse).returns(T::Boolean) }
  def self.should_retry?(response)
    response.code == "429" || (response.code.to_i >= 500)
  end

  sig { params(attempt: Integer, response: T.nilable(Net::HTTPResponse)).returns(Float) }
  def self.backoff_for(attempt, response)
    retry_after = response&.[]("Retry-After")
    return retry_after.to_f if retry_after && retry_after.to_f.positive?

    exponent = attempt - 1
    base = BASE_BACKOFF_SECONDS * (2.0**exponent)
    jitter = Kernel.rand * 0.25
    (base + jitter).to_f
  end

  private_class_method :raw_value, :safe_pct, :perform_request, :should_retry?, :backoff_for
end
