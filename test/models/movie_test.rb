require "test_helper"

class MovieTest < ActiveSupport::TestCase
  test "ordered_by_rating sorts by average rating descending" do
    high = Movie.create!(title: "High Rated")
    low = Movie.create!(title: "Low Rated")
    Review.create!(movie: high, reviewer: "A", stars: 5)
    Review.create!(movie: low, reviewer: "B", stars: 1)

    assert_equal [ "High Rated", "Low Rated" ], Movie.ordered_by_rating.map(&:title)
  end

  test "movies with no reviews sort last with a zero rating" do
    rated = Movie.create!(title: "Rated")
    unrated = Movie.create!(title: "Unrated")
    Review.create!(movie: rated, reviewer: "A", stars: 1)

    ordered = Movie.ordered_by_rating.to_a
    assert_equal [ "Rated", "Unrated" ], ordered.map(&:title)
    assert_equal 0.0, ordered.last.average_rating
    assert_equal 0, ordered.last.review_count
  end

  test "title must be present and unique" do
    Movie.create!(title: "Unique")
    assert_not Movie.new(title: "").valid?
    assert_not Movie.new(title: "Unique").valid?
  end
end
