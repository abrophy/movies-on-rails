require "rails_helper"

RSpec.describe Review, type: :model do
  let(:movie) { Movie.create!(title: "A Movie") }

  it "requires stars to be an integer between 1 and 5" do
    expect(Review.new(movie: movie, reviewer: "A", stars: 5)).to be_valid
    expect(Review.new(movie: movie, reviewer: "A", stars: 6)).not_to be_valid
    expect(Review.new(movie: movie, reviewer: "A", stars: 0)).not_to be_valid
  end

  it "requires a reviewer" do
    expect(Review.new(movie: movie, reviewer: "", stars: 3)).not_to be_valid
  end

  it "allows a reviewer to review a movie only once" do
    Review.create!(movie: movie, reviewer: "A", stars: 3)

    expect(Review.new(movie: movie, reviewer: "A", stars: 5)).not_to be_valid
  end
end
