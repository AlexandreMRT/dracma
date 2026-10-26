# frozen_string_literal: true

require "test_helper"

class SignalBacktesterTest < ActiveSupport::TestCase
  test "measures forward returns only after observed signals" do
    rows = [
      { quote_date: Date.new(2026, 1, 1), price_brl: 100.0, signal_rsi_oversold: 1 },
      { quote_date: Date.new(2026, 1, 2), price_brl: 110.0, signal_rsi_oversold: 0 },
      { quote_date: Date.new(2026, 1, 3), price_brl: 90.0, signal_rsi_oversold: 0 },
      { quote_date: Date.new(2026, 1, 4), price_brl: 120.0, signal_rsi_oversold: 0 },
      { quote_date: Date.new(2026, 1, 5), price_brl: 80.0, signal_rsi_oversold: 0 }
    ]

    result = SignalBacktester.run(rows, signal_key: :signal_rsi_oversold, horizons: [ 1, 3 ])

    assert_equal 1, result[:signal_events]
    assert_equal 1, result.dig(:horizons, "1d", :observations)
    assert_in_delta 10.0, result.dig(:horizons, "1d", :average_return_pct)
    assert_in_delta 100.0, result.dig(:horizons, "1d", :hit_rate_pct)
    assert_in_delta 20.0, result.dig(:horizons, "3d", :average_return_pct)
  end

  test "returns empty statistics when signals have no future observation" do
    rows = [ { quote_date: Date.current, price_brl: 10.0, signal: true } ]

    result = SignalBacktester.run(rows, signal_key: :signal, horizons: [ 1 ])

    assert_equal 1, result[:signal_events]
    assert_equal 0, result.dig(:horizons, "1d", :observations)
    assert_nil result.dig(:horizons, "1d", :average_return_pct)
  end
end
