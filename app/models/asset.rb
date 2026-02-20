class Asset < ApplicationRecord
  has_many :quotes, dependent: :destroy

  validates :ticker, presence: true, uniqueness: true
  validates :name, presence: true
  validates :sector, presence: true
  validates :asset_type, presence: true, inclusion: { in: %w[stock commodity crypto currency] }
end
