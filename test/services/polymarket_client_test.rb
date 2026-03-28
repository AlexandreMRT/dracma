# frozen_string_literal: true

require "test_helper"

class PolymarketClientTest < ActiveSupport::TestCase
  test "fetch_markets returns parsed payload for success" do
    payload = [ { "id" => "1", "question" => "Will BTC rise?" } ]

    stub_request(:get, %r{\Ahttps://gamma-api\.polymarket\.com/markets\?.*\z})
      .to_return(status: 200, body: payload.to_json, headers: { "Content-Type" => "application/json" })

    result = PolymarketClient.fetch_markets(limit: 1, category: "crypto")

    assert_equal payload, result
  end

  test "fetch_markets returns empty array for non success" do
    stub_request(:get, %r{\Ahttps://gamma-api\.polymarket\.com/markets\?.*\z})
      .to_return(status: 503, body: "service unavailable")

    assert_empty PolymarketClient.fetch_markets(limit: 1)
  end

  test "match finds relevant asset keys from text" do
    keys = PolymarketClient.match(
      "Will bitcoin break all-time highs this year?",
      "Markets are pricing a fed rate cut soon"
    )

    assert_includes keys, "BTC-USD"
    assert_includes keys, "MACRO_FED"
  end

  test "sentiment_from_market classifies bullish from yes probability" do
    market = {
      "question" => "Will BTC break 100k?",
      "outcomes" => "[\"Yes\",\"No\"]",
      "outcomePrices" => "[\"0.71\",\"0.29\"]",
      "volume24hr" => "1234.5",
      "volumeNum" => "100000"
    }

    result = PolymarketClient.sentiment_from_market(market)

    assert_equal "Will BTC break 100k?", result[:question]
    assert_in_delta 0.71, result[:yes_probability], 0.001
    assert_equal "bullish", result[:sentiment]
    assert_in_delta 1234.5, result[:volume_24h], 0.001
    assert_in_delta 100000.0, result[:volume_total], 0.001
  end

  test "aggregate computes volume weighted sentiment score" do
    markets = [
      { yes_probability: 0.8, volume_24h: 1000.0 },
      { yes_probability: 0.4, volume_24h: 500.0 }
    ]

    result = PolymarketClient.aggregate(markets)

    assert_in_delta 0.333, result[:score], 0.001
    assert_equal "bullish", result[:label]
    assert_in_delta (Math.log10(1501.0) / 7.0).round(3), result[:confidence], 0.001
    assert_equal 2, result[:market_count]
    assert_in_delta 1500.0, result[:total_volume], 0.001
    assert_equal markets.first, result[:top_market]
  end

  test "aggregate returns empty sentiment contract for empty input" do
    result = PolymarketClient.aggregate([])

    assert_nil result[:score]
    assert_nil result[:label]
    assert_nil result[:confidence]
    assert_equal 0, result[:market_count]
    assert_equal 0, result[:total_volume]
  end

  test "fetch_sentiment deduplicates markets and sorts by volume" do
    bitcoin_low_volume = {
      "id" => "m1",
      "question" => "Will bitcoin rally this week?",
      "description" => "",
      "outcomes" => "[\"Yes\",\"No\"]",
      "outcomePrices" => "[\"0.60\",\"0.40\"]",
      "volume24hr" => "50",
      "volumeNum" => "1000"
    }
    bitcoin_high_volume = {
      "id" => "m2",
      "question" => "Will bitcoin reach 100k this year?",
      "description" => "",
      "outcomes" => "[\"Yes\",\"No\"]",
      "outcomePrices" => "[\"0.65\",\"0.35\"]",
      "volume24hr" => "150",
      "volumeNum" => "3000"
    }
    fed_market = {
      "id" => "m3",
      "question" => "Will the fed rate be cut this quarter?",
      "description" => "",
      "outcomes" => "[\"Yes\",\"No\"]",
      "outcomePrices" => "[\"0.45\",\"0.55\"]",
      "volume24hr" => "80",
      "volumeNum" => "2000"
    }

    fetch_stub = lambda do |limit:, active: true, closed: false, category: nil|
      case category
      when "crypto"
        [ bitcoin_low_volume ]
      when "economics"
        [ fed_market ]
      when nil
        [ bitcoin_low_volume, bitcoin_high_volume ]
      else
        []
      end
    end

    with_singleton_stub(PolymarketClient, :fetch_markets, fetch_stub) do
      result = PolymarketClient.fetch_sentiment(max_markets: 200)

      assert_equal 2, result["BTC-USD"].size
      assert_equal "Will bitcoin reach 100k this year?", result["BTC-USD"].first[:question]
      assert_in_delta 150.0, result["BTC-USD"].first[:volume_24h], 0.001
      assert_equal 1, result["MACRO_FED"].size
      assert_equal "Will the fed rate be cut this quarter?", result["MACRO_FED"].first[:question]
    end
  end

  private

  def with_singleton_stub(object, method_name, implementation)
    original_method = object.method(method_name)
    object.define_singleton_method(method_name, implementation)
    yield
  ensure
    object.define_singleton_method(method_name, original_method)
  end
end
