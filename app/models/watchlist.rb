class Watchlist < ApplicationRecord
  belongs_to :user

  validates :ticker, presence: true, uniqueness: { scope: :user_id }
end
