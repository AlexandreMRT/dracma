class Portfolio < ApplicationRecord
  belongs_to :user
  has_many :positions, dependent: :destroy
  has_many :transactions, dependent: :destroy

  validates :name, presence: true
end
