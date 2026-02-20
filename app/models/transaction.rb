class Transaction < ApplicationRecord
  belongs_to :portfolio

  enum :transaction_type, { buy: 1, sell: 2, dividend: 3, split: 4, merge: 5 }, prefix: true

  validates :ticker, presence: true
  validates :transaction_type, presence: true
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :price_brl, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :total_brl, presence: true
  validates :transaction_date, presence: true
end
