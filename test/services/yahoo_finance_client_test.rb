# frozen_string_literal: true

require "test_helper"

class YahooFinanceClientTest < ActiveSupport::TestCase
  test "history parses quote payload and skips rows without close" do
    timestamp = 1_700_000_000
    payload = {
      "chart" => {
        "result" => [
          {
            "meta" => { "symbol" => "PETR4.SA" },
            "timestamp" => [ timestamp, timestamp + 86_400 ],
            "indicators" => {
              "quote" => [
                {
                  "open" => [ 10.0, 11.0 ],
                  "high" => [ 11.0, 12.0 ],
                  "low" => [ 9.0, 10.0 ],
                  "close" => [ 10.5, nil ],
                  "volume" => [ 1000, 1100 ]
                }
              ]
            }
          }
        ]
      }
    }

    stub_request(:get, %r{\Ahttps://query1\.finance\.yahoo\.com/v8/finance/chart/PETR4\.SA\?.*\z})
      .to_return(status: 200, body: payload.to_json, headers: { "Content-Type" => "application/json" })

    result = without_sleep { YahooFinanceClient.history("PETR4.SA", range: "1mo", interval: "1d") }

    assert_equal "PETR4.SA", result[:meta]["symbol"]
    assert_equal 1, result[:quotes].size
    quote = result[:quotes].first

    assert_equal Time.at(timestamp).utc.to_date, quote[:date]
    assert_in_delta(10.0, quote[:open])
    assert_in_delta(11.0, quote[:high])
    assert_in_delta(9.0, quote[:low])
    assert_in_delta(10.5, quote[:close])
    assert_in_delta(1000.0, quote[:volume])
  end

  test "history retries on 429 and succeeds" do
    payload = {
      "chart" => {
        "result" => [
          {
            "meta" => { "symbol" => "AAPL" },
            "timestamp" => [ 1_700_000_000 ],
            "indicators" => {
              "quote" => [
                {
                  "open" => [ 100.0 ],
                  "high" => [ 101.0 ],
                  "low" => [ 99.0 ],
                  "close" => [ 100.5 ],
                  "volume" => [ 2000 ]
                }
              ]
            }
          }
        ]
      }
    }

    request = stub_request(:get, %r{\Ahttps://query1\.finance\.yahoo\.com/v8/finance/chart/AAPL\?.*\z})
      .to_return(
        { status: 429, body: "", headers: { "Retry-After" => "0" } },
        { status: 200, body: payload.to_json, headers: { "Content-Type" => "application/json" } }
      )

    result = without_sleep { YahooFinanceClient.history("AAPL", range: "5d") }

    assert_equal "AAPL", result[:meta]["symbol"]
    assert_equal 1, result[:quotes].size
    assert_requested request, times: 2
  end

  test "history raises error when chart result is missing" do
    payload = { "chart" => { "result" => nil } }

    stub_request(:get, %r{\Ahttps://query1\.finance\.yahoo\.com/v8/finance/chart/VALE3\.SA\?.*\z})
      .to_return(status: 200, body: payload.to_json, headers: { "Content-Type" => "application/json" })

    error = assert_raises(YahooFinanceClient::Error) do
      without_sleep { YahooFinanceClient.history("VALE3.SA") }
    end

    assert_includes error.message, "No data for VALE3.SA"
  end

  test "info maps raw fields and normalizes percent values" do
    payload = {
      "quoteSummary" => {
        "result" => [
          {
            "summaryDetail" => {
              "marketCap" => { "raw" => 1000 },
              "trailingPE" => { "raw" => 18.5 },
              "priceToBook" => { "raw" => 2.2 },
              "dividendYield" => { "raw" => 0.045 },
              "fiftyTwoWeekHigh" => { "raw" => 130.0 },
              "fiftyTwoWeekLow" => { "raw" => 80.0 }
            },
            "defaultKeyStatistics" => {
              "forwardPE" => { "raw" => 16.0 },
              "trailingEps" => { "raw" => 6.2 },
              "beta" => { "raw" => 1.1 }
            },
            "financialData" => {
              "profitMargins" => { "raw" => 0.22 },
              "returnOnEquity" => { "raw" => 15.0 },
              "debtToEquity" => { "raw" => 85.0 },
              "recommendationKey" => { "raw" => "buy" },
              "targetMeanPrice" => { "raw" => 140.0 },
              "numberOfAnalystOpinions" => { "raw" => 27 }
            }
          }
        ]
      }
    }

    stub_request(:get, %r{\Ahttps://query1\.finance\.yahoo\.com/v10/finance/quoteSummary/AAPL\?.*\z})
      .to_return(status: 200, body: payload.to_json, headers: { "Content-Type" => "application/json" })

    result = without_sleep { YahooFinanceClient.info("AAPL") }

    assert_equal 1000, result[:market_cap]
    assert_in_delta(18.5, result[:pe_ratio])
    assert_in_delta(16.0, result[:forward_pe])
    assert_in_delta(2.2, result[:pb_ratio])
    assert_in_delta(4.5, result[:dividend_yield])
    assert_in_delta(22.0, result[:profit_margin])
    assert_in_delta(15.0, result[:roe])
    assert_equal "buy", result[:analyst_rating]
    assert_equal 27, result[:num_analysts]
  end

  test "info returns empty hash on malformed payload" do
    stub_request(:get, %r{\Ahttps://query1\.finance\.yahoo\.com/v10/finance/quoteSummary/MSFT\?.*\z})
      .to_return(status: 200, body: "not-json", headers: { "Content-Type" => "application/json" })

    assert_empty(without_sleep { YahooFinanceClient.info("MSFT") })
  end

  test "backoff_for uses retry-after header when present" do
    response = Net::HTTPTooManyRequests.new("1.1", "429", "Too Many Requests")
    response["Retry-After"] = "2.5"

    assert_in_delta(2.5, YahooFinanceClient.send(:backoff_for, 2, response))
  end

  private

  def without_sleep
    original_sleep = YahooFinanceClient.method(:sleep)
    YahooFinanceClient.define_singleton_method(:sleep) { |_seconds| nil }
    yield
  ensure
    YahooFinanceClient.define_singleton_method(:sleep, original_sleep)
  end
end
