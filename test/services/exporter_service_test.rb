# frozen_string_literal: true

require "test_helper"

class ExporterServiceTest < ActiveSupport::TestCase
  setup do
    Rails.cache.clear
  end

  test "latest_quotes returns the most recent quote per asset ordered by ticker" do
    Quote.create!(asset: assets(:petr4), price_brl: 35.0, quote_date: Date.new(2026, 2, 9))
    Quote.create!(asset: assets(:aapl), price_brl: 900.0, quote_date: Date.new(2026, 2, 9))

    quotes = ExporterService.latest_quotes

    assert_equal [ quotes(:aapl_today), quotes(:petr4_today) ], quotes
  end

  test "latest_rows uses cache for unchanged data" do
    cached_rows = [ { ticker: "CACHED" } ]
    cache_key = ExporterService.send(:cache_key_for, "latest_rows", quote_date: nil)
    cache = Rails.cache
    original_fetch = cache.method(:fetch)
    seen_key = nil

    cache.define_singleton_method(:fetch) do |key, **_options, &_block|
      seen_key = key
      cached_rows
    end

    assert_equal cached_rows, ExporterService.latest_rows
    assert_equal cache_key, seen_key
  ensure
    cache.define_singleton_method(:fetch, original_fetch)
  end

  test "dashboard_snapshot groups rows and derives movers" do
    snapshot = ExporterService.dashboard_snapshot

    assert_equal [ "PETR4" ], snapshot[:br_stocks].map { |row| row[:ticker] }
    assert_equal [ "AAPL" ], snapshot[:us_stocks].map { |row| row[:ticker] }
    assert_empty snapshot[:commodities]
    assert_empty snapshot[:crypto]
    assert_empty snapshot[:currency]
  end

  test "dashboard_snapshot derives movers signals and watchlist" do
    snapshot = ExporterService.dashboard_snapshot

    assert_equal "PETR4", snapshot[:gainers].first[:ticker]
    assert_equal "AAPL", snapshot[:losers].first[:ticker]
    assert_equal [ "AAPL" ], snapshot[:bullish].map { |row| row[:ticker] }
    assert_empty snapshot[:bearish]
    assert_includes snapshot[:watchlist_data].keys, :watchlist
    assert_includes snapshot[:watchlist_data].keys, :avoid_list
  end
end
