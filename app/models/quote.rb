class Quote < ApplicationRecord
  belongs_to :asset

  validates :price_brl, presence: true
  validates :quote_date, presence: true, uniqueness: { scope: :asset_id }
end
