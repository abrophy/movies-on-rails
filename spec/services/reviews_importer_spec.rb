require "rails_helper"
require "tmpdir"
require "fileutils"

RSpec.describe ReviewsImporter, type: :service do
  before do
    MoviesImporter.new(csv_fixture("movies.csv")).call
    @tmpdir = Dir.mktmpdir("reviews_importer_spec")
  end

  after do
    FileUtils.remove_entry(@tmpdir)
  end

  def write_csv(contents)
    path = File.join(@tmpdir, "reviews.csv")
    File.write(path, contents)
    Pathname.new(path)
  end

  it "imports reviews for known movies" do
    result = ReviewsImporter.new(csv_fixture("reviews.csv")).call

    expect(result.reviews).to eq(9)
    expect(result.errors).to be_empty
    expect(Review.count).to eq(9)
  end

  it "is idempotent across repeated runs" do
    importer = ReviewsImporter.new(csv_fixture("reviews.csv"))
    importer.call
    importer.call

    expect(Review.count).to eq(9)
  end

  it "raises InvalidStructureError when the columns are unexpected" do
    wrong = write_csv("Movie,Description,Year\nInception,desc,2010\n")

    expect { ReviewsImporter.new(wrong) }.to raise_error(CsvImport::InvalidStructureError, /Unrecognized CSV structure/)
    expect(Review.count).to eq(0)
  end

  it "skips reviews that reference unknown movies" do
    reviews = write_csv([
      "Movie,User,Stars,Review",
      "Gone in 60 seconds,Sam,4,Great",
      "Ghost Movie,Sam,5,Not real"
    ].join("\n") + "\n")

    result = ReviewsImporter.new(reviews).call

    expect(result.reviews).to eq(1)
    expect(result.errors.size).to eq(1)
    expect(result.errors.first[:line]).to eq(3)
    expect(result.errors.first[:message]).to match(/unknown movie "Ghost Movie"/)
  end

  it "skips reviews with invalid stars" do
    reviews = write_csv([
      "Movie,User,Stars,Review",
      "Gone in 60 seconds,Sam,4,Great",
      "Gone in 60 seconds,Pat,9,Too high"
    ].join("\n") + "\n")

    result = ReviewsImporter.new(reviews).call

    expect(result.reviews).to eq(1)
    expect(result.errors.size).to eq(1)
    expect(result.errors.first[:message]).to match(/invalid stars/)
  end
end
