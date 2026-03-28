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

  test "report_data keeps gainers and losers mutually exclusive" do
    report = ExporterService.report_data

    assert report[:top_movers][:gainers].all? { |row| row[:var_1d].to_f.positive? }
    assert report[:top_movers][:losers].all? { |row| row[:var_1d].to_f.negative? }

    gainers = report[:top_movers][:gainers].map { |row| row[:ticker] }
    losers = report[:top_movers][:losers].map { |row| row[:ticker] }
    assert_empty(gainers & losers)
  end

  test "export_ai_report emits comprehensive schema with sorted exclusive movers" do
    filename = "ai_report_test_#{SecureRandom.hex(4)}.json"
    path = ExporterService.export_ai_report(filename: filename)

    payload = JSON.parse(File.read(path))

    assert_equal "comprehensive_daily_summary", payload.dig("metadata", "report_type")
    assert_predicate payload.dig("metadata", "generated_at"), :present?
    assert_predicate payload.dig("metadata", "data_date"), :present?

    assert payload.key?("macro_context")
    assert payload.key?("market_movers")
    assert payload.key?("assets")
    assert payload.key?("ai_actionable_insights")

    gainers = payload.dig("market_movers", "top_gainers_1d")
    losers = payload.dig("market_movers", "top_losers_1d")

    assert gainers.each_cons(2).all? { |a, b| a["change_pct"] >= b["change_pct"] }
    assert losers.each_cons(2).all? { |a, b| a["change_pct"] <= b["change_pct"] }
    assert gainers.all? { |row| row["change_pct"].to_f.positive? }
    assert losers.all? { |row| row["change_pct"].to_f.negative? }

    gainers_tickers = gainers.map { |row| row["ticker"] }
    losers_tickers = losers.map { |row| row["ticker"] }
    assert_empty(gainers_tickers & losers_tickers)

    first_asset = payload.fetch("assets").first
    assert first_asset.key?("price_data")
    assert first_asset.key?("fundamentals")
    assert first_asset.key?("technicals")
    assert first_asset.key?("sentiment")

    summary_text = payload.dig("ai_actionable_insights", "market_summary_text")
    assert_includes summary_text, "\n"
  ensure
    FileUtils.rm_f(path) if path
  end
end
