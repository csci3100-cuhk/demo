class Review < ApplicationRecord
  # Associations (ESaaS §5.3, §5.4)
  # "The foreign key belongs to me"
  belongs_to :movie
  belongs_to :moviegoer

  # Validations
  validates :potatoes, presence: true,
                       numericality: { only_integer: true,
                                       greater_than_or_equal_to: 1,
                                       less_than_or_equal_to: 5 }

  # A moviegoer can only review a movie once
  validates :moviegoer_id, uniqueness: { scope: :movie_id,
                                         message: 'has already reviewed this movie' }
end
