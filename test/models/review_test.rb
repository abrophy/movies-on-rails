require "test_helper"

class ReviewTest < ActiveSupport::TestCase
  def setup
    @movie = Movie.create!(title: "A Movie")
  end

  test "stars must be an integer between 1 and 5" do
    assert Review.new(movie: @movie, reviewer: "A", stars: 5).valid?
    assert_not Review.new(movie: @movie, reviewer: "A", stars: 6).valid?
    assert_not Review.new(movie: @movie, reviewer: "A", stars: 0).valid?
  end

  test "reviewer must be present" do
    assert_not Review.new(movie: @movie, reviewer: "", stars: 3).valid?
  end

  test "a reviewer can only review a movie once" do
    Review.create!(movie: @movie, reviewer: "A", stars: 3)
    assert_not Review.new(movie: @movie, reviewer: "A", stars: 5).valid?
  end
end
