require "test_helper"
require "tmpdir"
require "fileutils"

class ReviewsImporterTest < ActiveSupport::TestCase
  def setup
    # Reviews join movies by title, so the movies must exist first.
    MoviesImporter.new(Rails.root.join("movies.csv")).call
    @tmpdir = Dir.mktmpdir("reviews_importer_test")
  end

  def teardown
    FileUtils.remove_entry(@tmpdir)
  end

  def write_csv(contents)
    path = File.join(@tmpdir, "reviews.csv")
    File.write(path, contents)
    Pathname.new(path)
  end

  test "imports reviews for known movies" do
    result = ReviewsImporter.new(Rails.root.join("reviews.csv")).call

    assert_equal 9, result.reviews
    assert_empty result.errors
    assert_equal 9, Review.count
  end

  test "is idempotent across repeated runs" do
    importer = ReviewsImporter.new(Rails.root.join("reviews.csv"))
    importer.call
    importer.call

    assert_equal 9, Review.count
  end

  test "raises InvalidStructureError when the columns are unexpected" do
    wrong = write_csv("Movie,Description,Year\nInception,desc,2010\n")

    error = assert_raises(CsvImport::InvalidStructureError) { ReviewsImporter.new(wrong) }
    assert_match(/Unrecognized CSV structure/, error.message)
    assert_equal 0, Review.count
  end

  test "skips reviews that reference unknown movies" do
    reviews = write_csv([
      "Movie,User,Stars,Review",
      "Gone in 60 seconds,Sam,4,Great",
      "Ghost Movie,Sam,5,Not real"
    ].join("\n") + "\n")

    result = ReviewsImporter.new(reviews).call

    assert_equal 1, result.reviews
    assert_equal 1, result.errors.size
    assert_equal 3, result.errors.first[:line]
    assert_match(/unknown movie "Ghost Movie"/, result.errors.first[:message])
  end

  test "skips reviews with invalid stars" do
    reviews = write_csv([
      "Movie,User,Stars,Review",
      "Gone in 60 seconds,Sam,4,Great",
      "Gone in 60 seconds,Pat,9,Too high"
    ].join("\n") + "\n")

    result = ReviewsImporter.new(reviews).call

    assert_equal 1, result.reviews
    assert_equal 1, result.errors.size
    assert_match(/invalid stars/, result.errors.first[:message])
  end
end
