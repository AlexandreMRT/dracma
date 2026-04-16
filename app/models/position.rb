class Position < ApplicationRecord
  belongs_to :portfolio

  normalizes :broker, with: ->(broker) { broker.to_s.strip }

  validates :ticker, presence: true, uniqueness: { scope: [ :portfolio_id, :broker ] }
  validates :broker, presence: true
  validates :quantity, numericality: { greater_than_or_equal_to: 0 }
  validates :avg_price_brl, numericality: { greater_than_or_equal_to: 0 }
end
