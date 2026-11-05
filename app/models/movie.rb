class Movie < ApplicationRecord
  has_many :appearances, dependent: :destroy
  has_many :actors, -> { distinct }, through: :appearances
  has_many :filming_locations, -> { distinct }, through: :appearances
  has_many :reviews, dependent: :destroy

  validates :title, presence: true, uniqueness: true

  # Returns movies with computed average rating and review count.
  # Movies with no reviews are included (LEFT JOIN) with an average of 0,
  # so they sort below any movie that actually has ratings.
  scope :with_average_rating, -> {
    left_joins(:reviews)
      .select(
        "movies.*",
        "COALESCE(AVG(reviews.stars), 0) AS average_rating",
        "COUNT(reviews.id) AS review_count"
      )
      .group("movies.id")
  }

  scope :ordered_by_rating, -> {
    with_average_rating
      .order("average_rating DESC", "review_count DESC", "movies.title ASC")
  }

  def average_rating
    self[:average_rating].to_f
  end

  def review_count
    self[:review_count] || reviews.size
  end
end
