require "test_helper"

class CsvImporterTest < ActiveSupport::TestCase
  def setup
    @importer = CsvImporter.new(
      movies_path: Rails.root.join("movies.csv"),
      reviews_path: Rails.root.join("reviews.csv")
    )
  end

  test "normalizes the denormalized CSV into the expected entities" do
    result = @importer.call

    assert_equal 2, result.movies
    assert_equal 5, result.actors
    assert_equal 3, result.filming_locations
    assert_equal 14, result.appearances
    assert_equal 9, result.reviews
  end

  test "is idempotent across repeated runs" do
    @importer.call
    @importer.call

    assert_equal 2, Movie.count
    assert_equal 5, Actor.count
    assert_equal 3, FilmingLocation.count
    assert_equal 14, Appearance.count
    assert_equal 9, Review.count
  end

  test "deduplicates actors shared across movies" do
    @importer.call

    assert_equal 1, Actor.where(name: "Leonardo Di Caprio").count
    leo = Actor.find_by(name: "Leonardo Di Caprio")
    assert_equal [ "Gone in 60 seconds", "Inception" ], leo.movies.order(:title).pluck(:title)
  end

  test "links movies to their cast and locations" do
    @importer.call

    gone = Movie.find_by(title: "Gone in 60 seconds")
    assert_equal [ "Giovani Ribisi", "Leonardo Di Caprio", "Nicolas Cage" ], gone.actors.order(:name).pluck(:name)
    assert_equal [ "Lone Pine", "Los Angeles" ], gone.filming_locations.order(:name).pluck(:name)
  end
end
