class Position < ApplicationRecord
  belongs_to :portfolio

  validates :ticker, presence: true, uniqueness: { scope: :portfolio_id }
  validates :quantity, numericality: { greater_than_or_equal_to: 0 }
  validates :avg_price_brl, numericality: { greater_than_or_equal_to: 0 }
end
