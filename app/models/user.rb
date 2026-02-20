class User < ApplicationRecord
  has_many :watchlists, dependent: :destroy
  has_many :portfolios, dependent: :destroy

  validates :google_id, presence: true, uniqueness: true
  validates :email, presence: true, uniqueness: true
  validates :name, presence: true
end
