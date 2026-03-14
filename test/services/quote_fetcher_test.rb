# frozen_string_literal: true

require "test_helper"

class QuoteFetcherTest < ActiveSupport::TestCase
  test "fetch_catalog collects results and counts errors" do
    fetcher = QuoteFetcher.new
    entries = [
      { ticker: "PETR4.SA" },
      { ticker: "AAPL" },
      { ticker: "BTC-USD" }
    ]
    responses = {
      "PETR4.SA" => { ticker: "PETR4.SA" },
      "AAPL" => nil,
      "BTC-USD" => { ticker: "BTC-USD" }
    }

    fetcher.define_singleton_method(:worker_count) { 3 }
    fetcher.define_singleton_method(:fetch_single) { |entry| responses[entry[:ticker]] }

    results, errors = fetcher.send(:fetch_catalog, entries)

    assert_equal [ "BTC-USD", "PETR4.SA" ], results.map { |result| result[:ticker] }.sort
    assert_equal 1, errors
  end
end
