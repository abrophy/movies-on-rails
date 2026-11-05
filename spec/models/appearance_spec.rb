require "rails_helper"

RSpec.describe Appearance, type: :model do
  it "requires the movie, actor, and location combination to be unique" do
    movie = Movie.create!(title: "A Movie")
    actor = Actor.create!(name: "An Actor")
    location = FilmingLocation.create!(name: "A Location", country: "US")

    Appearance.create!(movie: movie, actor: actor, filming_location: location)
    duplicate = Appearance.new(movie: movie, actor: actor, filming_location: location)

    expect(duplicate).not_to be_valid
  end
end
