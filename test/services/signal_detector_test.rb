# frozen_string_literal: true

require "test_helper"

class SignalDetectorTest < ActiveSupport::TestCase
  test "neutral result for bland data" do
    data = { rsi_14: 50.0, week_52_high: 100, week_52_low: 50, close: 75,
             volume_ratio: 1.0, ma_50_above_200: nil, above_ma_50: nil, above_ma_200: nil }
    result = SignalDetector.detect(data)

    assert_equal "neutral", result.summary
  end

  test "detects RSI oversold" do
    data = { rsi_14: 25.0, week_52_high: 100, week_52_low: 50, close: 55,
             volume_ratio: 1.0, ma_50_above_200: nil, above_ma_50: nil, above_ma_200: nil }
    result = SignalDetector.detect(data)

    assert result.rsi_oversold
  end

  test "detects RSI overbought" do
    data = { rsi_14: 75.0, week_52_high: 100, week_52_low: 50, close: 80,
             volume_ratio: 1.0, ma_50_above_200: nil, above_ma_50: nil, above_ma_200: nil }
    result = SignalDetector.detect(data)

    assert result.rsi_overbought
  end

  test "detects volume spike" do
    data = { rsi_14: 50.0, week_52_high: 100, week_52_low: 50, close: 75,
             volume_ratio: 5.0, ma_50_above_200: nil, above_ma_50: nil, above_ma_200: nil }
    result = SignalDetector.detect(data)

    assert result.volume_spike
  end

  test "detects golden cross" do
    data = { rsi_14: 50.0, week_52_high: 100, week_52_low: 50, close: 80,
             volume_ratio: 1.0, ma_50_above_200: 1, above_ma_50: 1, above_ma_200: 1 }
    result = SignalDetector.detect(data)

    assert result.golden_cross
  end

  test "detects death cross" do
    data = { rsi_14: 50.0, week_52_high: 100, week_52_low: 50, close: 60,
             volume_ratio: 1.0, ma_50_above_200: 0, above_ma_50: 0, above_ma_200: 0 }
    result = SignalDetector.detect(data)

    assert result.death_cross
  end

  test "as_db_flags returns integer flags" do
    data = { rsi_14: 25.0, week_52_high: 100, week_52_low: 50, close: 52,
             volume_ratio: 5.0, ma_50_above_200: nil, above_ma_50: nil, above_ma_200: nil }
    result = SignalDetector.detect(data)
    flags = result.as_db_flags

    assert_equal 1, flags[:signal_rsi_oversold]
    assert_equal 1, flags[:signal_volume_spike]
  end
end
