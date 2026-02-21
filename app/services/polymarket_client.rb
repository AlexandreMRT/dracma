# frozen_string_literal: true
# typed: true

require "net/http"
require "json"

# Polymarket Gamma API client for prediction market sentiment.
# Ported from Python polymarket.py.
class PolymarketClient
  extend T::Sig

  GAMMA_API = "https://gamma-api.polymarket.com"

  MARKET_KEYWORDS = {
    "BTC-USD" => %w[bitcoin btc],
    "ETH-USD" => %w[ethereum eth],
    "MACRO_FED" => [ "federal reserve", "fed rate", "interest rate", "fomc", "rate cut", "rate hike" ],
    "MACRO_RECESSION" => %w[recession economic\ downturn gdp],
    "MACRO_INFLATION" => %w[inflation cpi consumer\ price],
    "MACRO_BRAZIL" => %w[brazil lula brazilian],
    "GC=F" => [ "gold price", "gold spot" ],
    "CL=F" => [ "oil price", "crude oil", "wti", "brent" ],
    "SECTOR_TECH" => %w[nvidia apple microsoft google meta ai\ stocks tech\ stocks],
    "GEOPOLITICS" => %w[china taiwan russia ukraine trade\ war tariff]
  }.freeze

  RELEVANT_CATEGORIES = %w[economics crypto business politics].freeze

  # Fetch markets from the Gamma API.
  sig { params(limit: Integer, active: T::Boolean, closed: T::Boolean, category: T.nilable(String)).returns(T::Array[T.untyped]) }
  def self.fetch_markets(limit: 100, active: true, closed: false, category: nil)
    params = { limit: limit, active: active.to_s, closed: closed.to_s, order: "volume24hr", ascending: "false" }
    params[:category] = category if category

    uri = URI("#{GAMMA_API}/markets")
    uri.query = URI.encode_www_form(params)

    response = Net::HTTP.get_response(uri)
    return [] unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(T.must(response.body))
  rescue StandardError => e
    Rails.logger.warn("Polymarket fetch error: #{e.message}")
    []
  end

  # Match a market question to tracked asset keys.
  sig { params(question: String, description: String).returns(T::Array[String]) }
  def self.match(question, description = "")
    text = "#{question} #{description}".downcase
    MARKET_KEYWORDS.select { |_, keywords| keywords.any? { |kw| text.include?(kw) } }.keys
  end

  # Calculate sentiment from a single market.
  sig { params(market: T::Hash[String, T.untyped]).returns(T::Hash[Symbol, T.untyped]) }
  def self.sentiment_from_market(market)
    outcomes = JSON.parse(market["outcomes"] || "[]") rescue []
    prices = JSON.parse(market["outcomePrices"] || "[]") rescue []
    price_map = outcomes.zip(prices).to_h

    yes_prob = (price_map["Yes"] || price_map["yes"] || prices.first)&.to_f

    sentiment = if yes_prob.nil?
                  nil
    elsif yes_prob >= 0.6
                  "bullish"
    elsif yes_prob <= 0.4
                  "bearish"
    else
                  "neutral"
    end

    {
      question: market["question"],
      yes_probability: yes_prob,
      sentiment: sentiment,
      volume_24h: market["volume24hr"]&.to_f,
      volume_total: market["volumeNum"]&.to_f
    }
  end

  # Fetch all relevant markets and match them to assets.
  sig { params(max_markets: Integer).returns(T::Hash[String, T::Array[T::Hash[Symbol, T.untyped]]]) }
  def self.fetch_sentiment(max_markets: 200)
    all_markets = []

    RELEVANT_CATEGORIES.each do |cat|
      all_markets.concat(fetch_markets(limit: 50, category: cat))
    end
    all_markets.concat(fetch_markets(limit: 50))

    # Deduplicate
    seen = Set.new
    unique = all_markets.select { |m| m["id"] && seen.add?(m["id"]) }

    asset_markets = Hash.new { |h, k| h[k] = [] }

    unique.each do |market|
      matched = match(market["question"] || "", market["description"] || "")
      next if matched.empty?

      data = sentiment_from_market(market)
      matched.each { |key| asset_markets[key] << data }
    end

    # Sort by volume, keep top 5 per asset
    asset_markets.each do |key, markets|
      asset_markets[key] = markets.sort_by { |m| -(m[:volume_24h] || 0) }.first(5)
    end

    asset_markets
  end

  # Aggregate sentiment from multiple markets (volume-weighted).
  sig { params(markets: T::Array[T::Hash[Symbol, T.untyped]]).returns(T::Hash[Symbol, T.untyped]) }
  def self.aggregate(markets)
    return { score: nil, label: nil, confidence: nil, market_count: 0, total_volume: 0 } if markets.empty?

    total_volume = 0.0
    weighted_prob = 0.0

    markets.each do |m|
      vol = m[:volume_24h] || 0
      prob = m[:yes_probability]
      next unless prob && vol > 0

      weighted_prob += prob * vol
      total_volume += vol
    end

    if total_volume > 0
      avg_prob = weighted_prob / total_volume
      score = (avg_prob - 0.5) * 2
      label = score >= 0.2 ? "bullish" : (score <= -0.2 ? "bearish" : "neutral")
      confidence = [ 1.0, Math.log10(total_volume + 1) / 7.0 ].min
    else
      score = label = confidence = nil
    end

    {
      score: score&.round(3),
      label: label,
      confidence: confidence&.round(3),
      market_count: markets.size,
      total_volume: total_volume,
      top_market: markets.first
    }
  end
end
