class Movie < ApplicationRecord
  has_many :reviews, dependent: :destroy
  has_many :moviegoers, through: :reviews

  # ============================================================
  # Validations (ESaaS §5.1)
  # ============================================================

  before_validation :normalize_title

  # RATINGS constant - list of valid ratings
  RATINGS = %w[G PG PG-13 R NC-17]

  # Grandfathered date for conditional validation
  @@grandfathered_date = Date.parse('1 Jan 1900')

  # Basic validations
  validates :title, presence: true, length: { maximum: 10 }
  validates :release_date, presence: true

  # Custom validator
  validate :released_1930_or_later

  # Conditional validation
  # Rating validation only applies if movie is NOT grandfathered
  validates :rating, inclusion: { in: RATINGS, message: '%{value} is not a valid rating' },
                     unless: :grandfathered?

  # ============================================================
  # Scopes - DRYing Out Queries (ESaaS §5.8)
  # ============================================================
  # Scopes are evaluated lazily and can be "stacked"

  scope :for_kids, -> { where(rating: ['G', 'PG']) }

  scope :with_good_reviews, lambda { |cutoff|
    joins(:reviews)
      .group(:id)
      .having('AVG(reviews.potatoes) > ?', cutoff)
  }

  scope :recently_reviewed, lambda { |n = 7|
    joins(:reviews)
      .where('reviews.created_at >= ?', n.days.ago)
      .distinct
  }

  scope :with_many_reviews, lambda { |count = 3|
    joins(:reviews)
      .group(:id)
      .having('COUNT(reviews.id) >= ?', count)
  }

  # ============================================================
  # Custom Validation Methods
  # ============================================================

  private

  def normalize_title
    self.title = title.to_s.strip
  end

  # Custom validator - release date must be 1930 or later
  def released_1930_or_later
    return if release_date.blank?
    if release_date < Date.parse('1 Jan 1930')
      errors.add(:release_date, 'must be 1930 or later')
    end
  end

  # Grandfathered movies don't need rating validation
  def grandfathered?
    release_date.present? && release_date < @@grandfathered_date
  end
end
