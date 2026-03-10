class Moviegoer < ApplicationRecord
  has_many :reviews, dependent: :destroy
  has_many :movies, through: :reviews

  # Validations
  validates :uid, presence: true
  validates :provider, presence: true
  validates :uid, uniqueness: { scope: :provider }

  # Class method to find or create from OmniAuth hash (ESaaS §5.2)
  def self.from_omniauth(auth_hash)
    find_or_create_by(provider: auth_hash['provider'], uid: auth_hash['uid']) do |user|
      user.name = auth_hash['info']['name']
      user.email = auth_hash['info']['email']
    end
  end
end
