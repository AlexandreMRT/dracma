# frozen_string_literal: true

# Static catalog of Brazilian brokerages (corretoras).
# Provides preset options for the broker field on positions/transactions.
module BrokerCatalog
  BROKERS = {
    "BTG Pactual" => { type: "full_service" },
    "Inter" => { type: "discount" },
    "Itaú Íon" => { type: "full_service" },
    "Nubank" => { type: "discount" },
    "XP Investimentos" => { type: "full_service" },
    "Rico" => { type: "discount" },
    "Clear" => { type: "discount" },
    "Genial" => { type: "discount" },
    "Ágora" => { type: "full_service" },
    "Toro" => { type: "discount" },
    "Guide" => { type: "full_service" },
    "Órama" => { type: "discount" },
    "Warren" => { type: "discount" },
    "Avenue" => { type: "discount" },
    "Binance" => { type: "crypto" },
    "Mercado Bitcoin" => { type: "crypto" }
  }.freeze

  def self.all
    BROKERS
  end

  def self.names
    BROKERS.keys.sort
  end

  def self.valid?(name)
    BROKERS.key?(name)
  end

  def self.info(name)
    BROKERS[name] || { type: "other" }
  end
end
