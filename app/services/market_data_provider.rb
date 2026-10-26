# frozen_string_literal: true

# Factory for market-data adapters. Keeping provider selection here prevents
# the ingestion pipeline from being coupled to a single vendor.
module MarketDataProvider
  def self.default
    case ENV.fetch("MARKET_DATA_PROVIDER", "yahoo_finance")
    when "yahoo_finance"
      YahooFinanceProvider.new
    else
      raise ArgumentError, "Unsupported market data provider: #{ENV["MARKET_DATA_PROVIDER"]}"
    end
  end
end
