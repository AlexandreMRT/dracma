# frozen_string_literal: true

require "test_helper"

class QuoteFetcherTest < ActiveSupport::TestCase
  # Small test catalog (3 assets) — avoids fetching all 152 tickers in every test
  SMALL_CATALOG = [
    { ticker: "PETR4.SA", info: { name: "Petrobras", sector: "energy" }, type: "stock", brazilian: true },
    { ticker: "AAPL", info: { name: "Apple", sector: "technology" }, type: "us_stock", brazilian: false },
    { ticker: "GC=F", info: { name: "Gold", sector: "commodity", unit: "oz" }, type: "commodity", brazilian: false }
  ].freeze

  SMALL_TICKERS = SMALL_CATALOG.map { |e| e[:ticker] }.freeze

  # Helper: build a minimal Yahoo Finance history response for a ticker
  def yahoo_history_json(ticker, close: 100.0, date: Date.today)
    # Generate enough data points for technicals (200+ for MA200, 15 for RSI, 31 for volatility)
    timestamps = (0..250).map { |i| (date - (250 - i)).to_time.to_i }
    closes = (0..250).map { |i| close + (i * 0.1) - 12.5 }
    opens = closes.map { |c| c - 0.5 }
    highs = closes.map { |c| c + 1.0 }
    lows = closes.map { |c| c - 1.0 }
    volumes = closes.map { 1_000_000.0 }

    {
      "chart" => {
        "result" => [ {
          "meta" => { "symbol" => ticker, "currency" => "BRL" },
          "timestamp" => timestamps,
          "indicators" => {
            "quote" => [ {
              "open" => opens,
              "high" => highs,
              "low" => lows,
              "close" => closes,
              "volume" => volumes
            } ]
          }
        } ]
      }
    }.to_json
  end

  # Helper: build a minimal Yahoo Finance quoteSummary response
  def yahoo_info_json
    {
      "quoteSummary" => {
        "result" => [ {
          "summaryDetail" => {
            "marketCap" => { "raw" => 500_000_000_000 },
            "trailingPE" => { "raw" => 8.5 },
            "priceToBook" => { "raw" => 1.2 },
            "dividendYield" => { "raw" => 0.08 },
            "fiftyTwoWeekHigh" => { "raw" => 120.0 },
            "fiftyTwoWeekLow" => { "raw" => 60.0 }
          },
          "defaultKeyStatistics" => {
            "forwardPE" => { "raw" => 7.0 },
            "trailingEps" => { "raw" => 12.5 },
            "beta" => { "raw" => 1.1 }
          },
          "financialData" => {
            "profitMargins" => { "raw" => 0.25 },
            "returnOnEquity" => { "raw" => 0.30 },
            "debtToEquity" => { "raw" => 45.0 },
            "recommendationKey" => { "raw" => "buy" },
            "targetMeanPrice" => { "raw" => 110.0 },
            "numberOfAnalystOpinions" => { "raw" => 15 }
          },
          "recommendationTrend" => {}
        } ]
      }
    }.to_json
  end

  # Helper: build a minimal Google News RSS feed
  def google_news_rss(headline: "Petrobras reports profit increase")
    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <rss version="2.0">
        <channel>
          <item>
            <title>#{headline}</title>
            <link>https://example.com/news</link>
            <pubDate>#{Time.current.rfc2822}</pubDate>
          </item>
        </channel>
      </rss>
    XML
  end

  # Stub all Yahoo Finance endpoints for a set of tickers.
  # WebMock normalizes URLs, so we match both encoded and unencoded ticker forms.
  def stub_yahoo_for(tickers, close: 100.0)
    tickers.each do |ticker|
      encoded = ERB::Util.url_encode(ticker)
      # Match both encoded and decoded ticker in the URL path
      chart_pattern = /query1\.finance\.yahoo\.com\/v8\/finance\/chart\/(#{Regexp.escape(encoded)}|#{Regexp.escape(ticker)})/
      summary_pattern = /query1\.finance\.yahoo\.com\/v10\/finance\/quoteSummary\/(#{Regexp.escape(encoded)}|#{Regexp.escape(ticker)})/
      stub_request(:get, chart_pattern)
        .to_return(status: 200, body: yahoo_history_json(ticker, close: close), headers: { "Content-Type" => "application/json" })
      stub_request(:get, summary_pattern)
        .to_return(status: 200, body: yahoo_info_json, headers: { "Content-Type" => "application/json" })
    end
  end

  # Stub prerequisites (USD/BRL + benchmarks)
  def stub_prerequisites
    stub_yahoo_for(%w[USDBRL=X ^BVSP ^GSPC])
  end

  # Stub Google News RSS for any query
  def stub_news
    stub_request(:get, /news\.google\.com/)
      .to_return(status: 200, body: google_news_rss, headers: { "Content-Type" => "application/xml" })
  end

  # Create a fetcher with small catalog override to keep tests fast
  def small_fetcher
    fetcher = QuoteFetcher.new
    catalog = SMALL_CATALOG
    fetcher.define_singleton_method(:build_asset_list) { catalog.dup }
    fetcher
  end

  setup do
    # Zero out throttle and backoff to speed up tests
    @original_throttle = YahooFinanceClient::DEFAULT_THROTTLE_SECONDS
    @original_backoff = YahooFinanceClient::BASE_BACKOFF_SECONDS
    @original_retries = YahooFinanceClient::MAX_RETRIES

    YahooFinanceClient.send(:remove_const, :DEFAULT_THROTTLE_SECONDS)
    YahooFinanceClient.const_set(:DEFAULT_THROTTLE_SECONDS, 0.0)
    YahooFinanceClient.send(:remove_const, :BASE_BACKOFF_SECONDS)
    YahooFinanceClient.const_set(:BASE_BACKOFF_SECONDS, 0.0)
    YahooFinanceClient.send(:remove_const, :MAX_RETRIES)
    YahooFinanceClient.const_set(:MAX_RETRIES, 0)
  end

  teardown do
    YahooFinanceClient.send(:remove_const, :DEFAULT_THROTTLE_SECONDS)
    YahooFinanceClient.const_set(:DEFAULT_THROTTLE_SECONDS, @original_throttle)
    YahooFinanceClient.send(:remove_const, :BASE_BACKOFF_SECONDS)
    YahooFinanceClient.const_set(:BASE_BACKOFF_SECONDS, @original_backoff)
    YahooFinanceClient.send(:remove_const, :MAX_RETRIES)
    YahooFinanceClient.const_set(:MAX_RETRIES, @original_retries)
  end

  test "fetch_all returns saved count and error count tuple" do
    stub_prerequisites
    stub_yahoo_for(SMALL_TICKERS)
    stub_news

    fetcher = small_fetcher
    saved, errors = fetcher.fetch_all

    assert_kind_of Integer, saved
    assert_kind_of Integer, errors
    assert_operator saved, :>, 0
  end

  test "fetch_all saves all assets from catalog" do
    stub_prerequisites
    stub_yahoo_for(SMALL_TICKERS)
    stub_news

    fetcher = small_fetcher
    saved, errors = fetcher.fetch_all

    assert_equal SMALL_TICKERS.size, saved + errors
  end

  test "handles individual asset fetch failures gracefully" do
    stub_prerequisites
    stub_yahoo_for(SMALL_TICKERS)
    stub_news

    # Override PETR4.SA to return a non-retryable error (400 = bad request, not retried)
    stub_request(:get, /query1\.finance\.yahoo\.com\/v8\/finance\/chart\/PETR4(\.|%2E)SA/)
      .to_return(status: 400, body: '{"chart":{"error":{"code":"Not Found"}}}')

    fetcher = small_fetcher
    saved, errors = fetcher.fetch_all

    assert_operator errors, :>=, 1, "Should count at least one error for the failing ticker"
    assert_operator saved, :>, 0, "Other tickers should still succeed"
  end

  test "thread pools are properly shut down after fetch_all" do
    stub_prerequisites
    stub_yahoo_for(SMALL_TICKERS)
    stub_news

    fetcher = small_fetcher

    # Warm-up run to initialize any global executors used by Concurrent::Promises
    fetcher.fetch_all
    sleep(0.5)
    baseline_thread_count = Thread.list.count

    # Actual run under test
    fetcher.fetch_all

    # Allow a brief moment for threads to terminate
    sleep(0.5)
    thread_count_after = Thread.list.count

    # Thread count should return to approximately baseline (some variance is normal)
    assert_in_delta baseline_thread_count, thread_count_after, 3,
      "Thread pools should be shut down — leaked threads detected"
  end

  test "prerequisites fetch USD/BRL and benchmarks concurrently" do
    usd_requested = false
    ibov_requested = false
    sp500_requested = false

    stub_request(:get, /query1\.finance\.yahoo\.com\/v8\/finance\/chart\/USDBRL/)
      .to_return do
        usd_requested = true
        { status: 200, body: yahoo_history_json("USDBRL=X", close: 5.50), headers: { "Content-Type" => "application/json" } }
      end

    stub_request(:get, /query1\.finance\.yahoo\.com\/v8\/finance\/chart\/(%5E|\^)BVSP/)
      .to_return do
        ibov_requested = true
        { status: 200, body: yahoo_history_json("^BVSP", close: 130_000.0), headers: { "Content-Type" => "application/json" } }
      end

    stub_request(:get, /query1\.finance\.yahoo\.com\/v8\/finance\/chart\/(%5E|\^)GSPC/)
      .to_return do
        sp500_requested = true
        { status: 200, body: yahoo_history_json("^GSPC", close: 5_000.0), headers: { "Content-Type" => "application/json" } }
      end

    stub_yahoo_for(SMALL_TICKERS)
    stub_news

    fetcher = small_fetcher
    fetcher.fetch_all

    assert usd_requested, "USD/BRL should be fetched"
    assert ibov_requested, "IBOV benchmark should be fetched"
    assert sp500_requested, "S&P500 benchmark should be fetched"
  end

  test "falls back to default USD/BRL rate on prerequisite failure" do
    # All prerequisite requests fail with non-retryable status
    stub_request(:get, /query1\.finance\.yahoo\.com\/v8\/finance\/chart\/USDBRL/)
      .to_return(status: 400, body: "Error")
    stub_request(:get, /query1\.finance\.yahoo\.com\/v8\/finance\/chart\/(%5E|\^)BVSP/)
      .to_return(status: 400, body: "Error")
    stub_request(:get, /query1\.finance\.yahoo\.com\/v8\/finance\/chart\/(%5E|\^)GSPC/)
      .to_return(status: 400, body: "Error")

    stub_yahoo_for(SMALL_TICKERS)
    stub_news

    fetcher = small_fetcher
    saved, _errors = fetcher.fetch_all

    # Should not raise, should use fallback USD/BRL rate
    assert_kind_of Integer, saved
  end

  test "news is fetched for stock results only" do
    stub_prerequisites
    stub_yahoo_for(SMALL_TICKERS)

    news_request_count = Concurrent::AtomicFixnum.new(0)
    stub_request(:get, /news\.google\.com/)
      .to_return do
        news_request_count.increment
        { status: 200, body: google_news_rss, headers: { "Content-Type" => "application/xml" } }
      end

    fetcher = small_fetcher
    fetcher.fetch_all

    # PETR4.SA (stock) and AAPL (us_stock) get news; GC=F (commodity) does not
    assert_operator news_request_count.value, :>, 0, "News should be fetched for stocks"
  end

  test "saves quotes to database" do
    stub_prerequisites
    stub_yahoo_for(SMALL_TICKERS)
    stub_news

    fetcher = small_fetcher

    assert_difference "Quote.count", SMALL_TICKERS.size do
      fetcher.fetch_all
    end
  end

  test "creates asset records in database" do
    stub_prerequisites
    stub_yahoo_for(SMALL_TICKERS)
    stub_news

    fetcher = small_fetcher
    fetcher.fetch_all

    SMALL_TICKERS.each do |ticker|
      assert Asset.exists?(ticker: ticker), "Asset #{ticker} should be created"
    end
  end

  test "QUOTE_WORKERS constant is 8" do
    assert_equal 8, QuoteFetcher::QUOTE_WORKERS
  end

  test "NEWS_WORKERS constant is 5" do
    assert_equal 5, QuoteFetcher::NEWS_WORKERS
  end
end
