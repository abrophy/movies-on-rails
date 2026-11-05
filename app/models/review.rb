class Review < ApplicationRecord
  belongs_to :movie

  validates :reviewer, presence: true
  validates :stars, presence: true, numericality: { only_integer: true, in: 1..5 }
  validates :reviewer, uniqueness: { scope: :movie_id }
end
