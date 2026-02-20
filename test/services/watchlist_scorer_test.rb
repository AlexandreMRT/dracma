# frozen_string_literal: true

require "test_helper"

class WatchlistScorerTest < ActiveSupport::TestCase
  test "returns watchlist and avoid_list" do
    items = [
      { ticker: "PETR4", nome: "Petrobras", tipo: "stock", rsi_14: 25.0,
        signal_summary: "bullish", signal_golden_cross: 1, above_ma_50: true,
        above_ma_200: true, signal_52w_low: 0, signal_52w_high: 0,
        signal_volume_spike: 1, news_sentiment_combined: 0.5, var_ytd: 25.0 }
    ]
    result = WatchlistScorer.build(items)

    assert_kind_of Hash, result
    assert_kind_of Array, result[:watchlist]
    assert_kind_of Array, result[:avoid_list]
  end

  test "high-scoring stock in watchlist" do
    items = [
      { ticker: "STRONG", nome: "Strong Stock", tipo: "stock", rsi_14: 20.0,
        signal_summary: "bullish", signal_golden_cross: 1, above_ma_50: true,
        above_ma_200: true, signal_52w_low: 1, signal_52w_high: 0,
        signal_volume_spike: 1, news_sentiment_combined: 0.5, var_ytd: 25.0 }
    ]
    result = WatchlistScorer.build(items, min_score: 3.0)

    assert_equal 1, result[:watchlist].size
    assert_equal "STRONG", result[:watchlist].first[:ticker]
  end

  test "bad stock in avoid list" do
    items = [
      { ticker: "WEAK", nome: "Weak Stock", tipo: "stock", rsi_14: 85.0,
        signal_summary: "bearish", signal_golden_cross: 0, above_ma_50: false,
        above_ma_200: false, signal_52w_low: 0, signal_52w_high: 1,
        signal_volume_spike: 0, news_sentiment_combined: -0.5, var_ytd: -25.0 }
    ]
    result = WatchlistScorer.build(items)

    assert_predicate result[:avoid_list], :any?
    assert_equal "WEAK", result[:avoid_list].first[:ticker]
  end

  test "ignores non-stock types" do
    items = [
      { ticker: "GC=F", nome: "Gold", tipo: "commodity", rsi_14: 20.0,
        signal_summary: "bullish" }
    ]
    result = WatchlistScorer.build(items)

    assert_empty result[:watchlist]
  end

  test "respects max_items" do
    items = 20.times.map do |i|
      { ticker: "STK#{i}", nome: "Stock #{i}", tipo: "stock", rsi_14: 20.0,
        signal_summary: "bullish", signal_golden_cross: 1, above_ma_50: true,
        above_ma_200: true, signal_52w_low: 1, signal_52w_high: 0,
        signal_volume_spike: 1, news_sentiment_combined: 0.5, var_ytd: 25.0 }
    end
    result = WatchlistScorer.build(items, max_items: 5)

    assert_operator result[:watchlist].size, :<=, 5
  end
end
