require "rails_helper"

RSpec.describe Movie, type: :model do
  describe ".ordered_by_rating" do
    it "sorts by average rating descending" do
      high = Movie.create!(title: "High Rated")
      low = Movie.create!(title: "Low Rated")
      Review.create!(movie: high, reviewer: "A", stars: 5)
      Review.create!(movie: low, reviewer: "B", stars: 1)

      expect(Movie.ordered_by_rating.map(&:title)).to eq([ "High Rated", "Low Rated" ])
    end

    it "sorts movies with no reviews last with a zero rating" do
      rated = Movie.create!(title: "Rated")
      unrated = Movie.create!(title: "Unrated")
      Review.create!(movie: rated, reviewer: "A", stars: 1)

      ordered = Movie.ordered_by_rating.to_a
      expect(ordered.map(&:title)).to eq([ "Rated", "Unrated" ])
      expect(ordered.last.average_rating).to eq(0.0)
      expect(ordered.last.review_count).to eq(0)
    end
  end

  describe "validations" do
    it "requires a unique, present title" do
      Movie.create!(title: "Unique")

      expect(Movie.new(title: "")).not_to be_valid
      expect(Movie.new(title: "Unique")).not_to be_valid
    end
  end
end
