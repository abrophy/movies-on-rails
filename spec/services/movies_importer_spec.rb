require "rails_helper"
require "tmpdir"
require "fileutils"

RSpec.describe MoviesImporter, type: :service do
  before do
    @tmpdir = Dir.mktmpdir("movies_importer_spec")
  end

  after do
    FileUtils.remove_entry(@tmpdir)
  end

  def write_csv(contents)
    path = File.join(@tmpdir, "movies.csv")
    File.write(path, contents)
    Pathname.new(path)
  end

  it "normalizes the denormalized CSV into the expected entities" do
    result = MoviesImporter.new(csv_fixture("movies.csv")).call

    expect(result.movies).to eq(2)
    expect(result.actors).to eq(5)
    expect(result.filming_locations).to eq(3)
    expect(result.appearances).to eq(14)
    expect(result.errors).to be_empty
  end

  it "is idempotent across repeated runs" do
    importer = MoviesImporter.new(csv_fixture("movies.csv"))
    importer.call
    importer.call

    expect(Movie.count).to eq(2)
    expect(Actor.count).to eq(5)
    expect(FilmingLocation.count).to eq(3)
    expect(Appearance.count).to eq(14)
  end

  it "deduplicates actors shared across movies" do
    MoviesImporter.new(csv_fixture("movies.csv")).call

    expect(Actor.where(name: "Leonardo Di Caprio").count).to eq(1)
    leo = Actor.find_by(name: "Leonardo Di Caprio")
    expect(leo.movies.order(:title).pluck(:title)).to eq([ "Gone in 60 seconds", "Inception" ])
  end

  it "links movies to their cast and locations" do
    MoviesImporter.new(csv_fixture("movies.csv")).call

    gone = Movie.find_by(title: "Gone in 60 seconds")
    expect(gone.actors.order(:name).pluck(:name)).to eq([ "Giovani Ribisi", "Leonardo Di Caprio", "Nicolas Cage" ])
    expect(gone.filming_locations.order(:name).pluck(:name)).to eq([ "Lone Pine", "Los Angeles" ])
  end

  it "raises InvalidStructureError when the columns are unexpected" do
    wrong = write_csv("Movie,User,Stars,Review\nInception,Sam,4,Great\n")

    expect { MoviesImporter.new(wrong) }.to raise_error(CsvImport::InvalidStructureError, /Unrecognized CSV structure/)
    expect(Movie.count).to eq(0)
  end

  it "skips malformed rows and imports the valid ones" do
    movies = write_csv([
      "Movie,Description,Year,Director,Actor,Filming location,Country",
      "Good Movie,A fine film,1999,Someone,Actor One,Studio City,US",
      "Bad Year Movie,A film,not-a-year,Someone,Actor Two,Studio City,US",
      "Good Movie,A fine film,1999,Someone,Actor Three,Studio City,US"
    ].join("\n") + "\n")

    result = MoviesImporter.new(movies).call

    expect(Movie.count).to eq(1)
    expect(Movie.find_by(title: "Good Movie").actors.order(:name).pluck(:name)).to eq([ "Actor One", "Actor Three" ])
    expect(result.appearances).to eq(2)
    expect(result.errors.size).to eq(1)
    expect(result.errors.first[:line]).to eq(3)
    expect(result.errors.first[:message]).to match(/invalid year/)
  end

  it "sanitizes whitespace and control characters" do
    movies = write_csv([
      "Movie,Description,Year,Director,Actor,Filming location,Country",
      %(  Padded Movie  ,desc,2001,Dir,"Actor\x00Name",Place,US)
    ].join("\n") + "\n")

    MoviesImporter.new(movies).call

    movie = Movie.find_by(title: "Padded Movie")
    expect(movie).to be_present
    expect(movie.year).to eq(2001)
    expect(movie.actors.pluck(:name)).to eq([ "ActorName" ])
  end

  it "deduplicates entities case-insensitively" do
    movies = write_csv([
      "Movie,Description,Year,Director,Actor,Filming location,Country",
      "Case Study,A film,2001,Someone,Nicolas Cage,Studio City,US",
      "case study,A film,2001,Someone,nicolas cage,STUDIO CITY,us"
    ].join("\n") + "\n")

    result = MoviesImporter.new(movies).call

    expect(result.movies).to eq(1)
    expect(result.actors).to eq(1)
    expect(result.filming_locations).to eq(1)
    expect(result.appearances).to eq(1)
    expect(Movie.first.title).to eq("Case Study")
    expect(Actor.first.name).to eq("Nicolas Cage")
  end
end
