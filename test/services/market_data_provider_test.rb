# frozen_string_literal: true

require "test_helper"

class MarketDataProviderTest < ActiveSupport::TestCase
  test "defaults to the configured Yahoo Finance adapter" do
    provider = MarketDataProvider.default

    assert_instance_of YahooFinanceProvider, provider
  end

  test "rejects unsupported providers" do
    ENV["MARKET_DATA_PROVIDER"] = "unknown"

    error = assert_raises(ArgumentError) { MarketDataProvider.default }

    assert_includes error.message, "Unsupported market data provider"
  ensure
    ENV.delete("MARKET_DATA_PROVIDER")
  end

  test "Yahoo adapter delegates history and fundamentals" do
    provider = YahooFinanceProvider.new
    history = { quotes: [ { close: 10.0 } ] }
    original_history = YahooFinanceClient.method(:history)
    original_info = YahooFinanceClient.method(:info)
    YahooFinanceClient.define_singleton_method(:history) { |_ticker, range: "max", interval: "1d"| history }
    YahooFinanceClient.define_singleton_method(:info) { |_ticker| { pe_ratio: 8.0 } }

    assert_equal history, provider.history("PETR4.SA")
    assert_equal({ pe_ratio: 8.0 }, provider.info("PETR4.SA"))
  ensure
    YahooFinanceClient.define_singleton_method(:history, original_history) if original_history
    YahooFinanceClient.define_singleton_method(:info, original_info) if original_info
  end
end
