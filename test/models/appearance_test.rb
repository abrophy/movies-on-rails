require "test_helper"

class AppearanceTest < ActiveSupport::TestCase
  test "movie, actor, and location combination is unique" do
    movie = Movie.create!(title: "A Movie")
    actor = Actor.create!(name: "An Actor")
    location = FilmingLocation.create!(name: "A Location", country: "US")

    Appearance.create!(movie: movie, actor: actor, filming_location: location)
    duplicate = Appearance.new(movie: movie, actor: actor, filming_location: location)

    assert_not duplicate.valid?
  end
end
