class User < ApplicationRecord
  has_many :watchlists, dependent: :destroy
  has_many :portfolios, dependent: :destroy

  validates :google_id, presence: true, uniqueness: true
  validates :email, presence: true, uniqueness: true
  validates :name, presence: true

  def self.from_omniauth(auth)
    user = find_or_initialize_by(google_id: auth.uid)
    user.email = auth.info.email
    user.name = auth.info.name
    user.picture_url = auth.info.image
    user.last_login = Time.current
    user
  end
end
