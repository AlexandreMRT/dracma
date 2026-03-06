# frozen_string_literal: true

require "test_helper"

class QuoteFetcherTest < ActiveSupport::TestCase
  test "fetch_all processes assets in parallel and fetches news for stock results" do
    fetcher = QuoteFetcher.new
    entries = [
      { ticker: "PETR4.SA", info: { name: "Petrobras" }, type: "stock", brazilian: true },
      { ticker: "AAPL", info: { name: "Apple" }, type: "us_stock", brazilian: false },
      { ticker: "GC=F", info: { name: "Gold" }, type: "commodity", brazilian: false },
      { ticker: "VALE3.SA", info: { name: "Vale" }, type: "stock", brazilian: true }
    ]

    active_calls = 0
    max_active_calls = 0
    news_tickers = []
    mutex = Mutex.new

    fetcher.define_singleton_method(:fetch_usd_brl) { 5.2 }
    fetcher.define_singleton_method(:fetch_benchmarks) { {} }
    fetcher.define_singleton_method(:build_asset_list) { entries }
    fetcher.define_singleton_method(:fetch_single) do |entry, **|
      begin
        mutex.synchronize do
          active_calls += 1
          max_active_calls = [ max_active_calls, active_calls ].max
        end

        sleep 0.05
        entry.merge(
          quote_data: { date: Date.current },
          price_brl: 10.0,
          price_usd: 2.0,
        )
      ensure
        mutex.synchronize { active_calls -= 1 }
      end
    end
    fetcher.define_singleton_method(:fetch_news_for) do |result|
      mutex.synchronize { news_tickers << result[:ticker] }
    end
    fetcher.define_singleton_method(:save_all) { |results| results.size }

    saved, errors = fetcher.fetch_all

    assert_equal 4, saved
    assert_equal 0, errors

    assert_operator max_active_calls, :>, 1
    assert_equal %w[AAPL PETR4.SA VALE3.SA], news_tickers.sort
  end

  test "fetch_all counts failed assets as errors" do
    fetcher = QuoteFetcher.new
    entries = [
      { ticker: "PETR4.SA", info: { name: "Petrobras" }, type: "stock", brazilian: true },
      { ticker: "AAPL", info: { name: "Apple" }, type: "us_stock", brazilian: false },
      { ticker: "GC=F", info: { name: "Gold" }, type: "commodity", brazilian: false }
    ]
    results_by_ticker = {
      "PETR4.SA" => entries[0].merge(quote_data: { date: Date.current }, price_brl: 10.0, price_usd: 2.0),
      "AAPL" => entries[1].merge(quote_data: { date: Date.current }, price_brl: 10.0, price_usd: 2.0),
      "GC=F" => nil
    }
    saved_results = nil

    fetcher.define_singleton_method(:fetch_usd_brl) { 5.2 }
    fetcher.define_singleton_method(:fetch_benchmarks) { {} }
    fetcher.define_singleton_method(:build_asset_list) { entries }
    fetcher.define_singleton_method(:fetch_single) { |entry, **| results_by_ticker[entry[:ticker]] }
    fetcher.define_singleton_method(:fetch_news_for) { |_result| }
    fetcher.define_singleton_method(:save_all) do |results|
      saved_results = results
      results.size
    end

    saved, errors = fetcher.fetch_all

    assert_equal %w[AAPL PETR4.SA], saved_results.map { |result| result[:ticker] }.sort
    assert_equal 2, saved
    assert_equal 1, errors
  end
end
