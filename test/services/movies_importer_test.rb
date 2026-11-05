require "test_helper"
require "tmpdir"
require "fileutils"

class MoviesImporterTest < ActiveSupport::TestCase
  def setup
    @importer = MoviesImporter.new(Rails.root.join("movies.csv"))
    @tmpdir = Dir.mktmpdir("movies_importer_test")
  end

  def teardown
    FileUtils.remove_entry(@tmpdir)
  end

  def write_csv(contents)
    path = File.join(@tmpdir, "movies.csv")
    File.write(path, contents)
    Pathname.new(path)
  end

  test "normalizes the denormalized CSV into the expected entities" do
    result = @importer.call

    assert_equal 2, result.movies
    assert_equal 5, result.actors
    assert_equal 3, result.filming_locations
    assert_equal 14, result.appearances
    assert_empty result.errors
  end

  test "is idempotent across repeated runs" do
    @importer.call
    @importer.call

    assert_equal 2, Movie.count
    assert_equal 5, Actor.count
    assert_equal 3, FilmingLocation.count
    assert_equal 14, Appearance.count
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

  test "raises InvalidStructureError when the columns are unexpected" do
    wrong = write_csv("Movie,User,Stars,Review\nInception,Sam,4,Great\n")

    error = assert_raises(CsvImport::InvalidStructureError) { MoviesImporter.new(wrong) }
    assert_match(/Unrecognized CSV structure/, error.message)
    assert_equal 0, Movie.count
  end

  test "skips malformed rows and imports the valid ones" do
    movies = write_csv([
      "Movie,Description,Year,Director,Actor,Filming location,Country",
      "Good Movie,A fine film,1999,Someone,Actor One,Studio City,US",
      "Bad Year Movie,A film,not-a-year,Someone,Actor Two,Studio City,US",
      "Good Movie,A fine film,1999,Someone,Actor Three,Studio City,US"
    ].join("\n") + "\n")

    result = MoviesImporter.new(movies).call

    assert_equal 1, Movie.count
    assert_equal [ "Actor One", "Actor Three" ], Movie.find_by(title: "Good Movie").actors.order(:name).pluck(:name)
    assert_equal 2, result.appearances

    assert_equal 1, result.errors.size
    assert_equal 3, result.errors.first[:line]
    assert_match(/invalid year/, result.errors.first[:message])
  end

  test "sanitizes whitespace and control characters" do
    movies = write_csv([
      "Movie,Description,Year,Director,Actor,Filming location,Country",
      %(  Padded Movie  ,desc,2001,Dir,"Actor\x00Name",Place,US)
    ].join("\n") + "\n")

    MoviesImporter.new(movies).call

    movie = Movie.find_by(title: "Padded Movie")
    assert movie
    assert_equal 2001, movie.year
    assert_equal [ "ActorName" ], movie.actors.pluck(:name)
  end
end
