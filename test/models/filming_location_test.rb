require "test_helper"

class FilmingLocationTest < ActiveSupport::TestCase
  test "name is unique within a country" do
    FilmingLocation.create!(name: "Los Angeles", country: "US")
    assert_not FilmingLocation.new(name: "Los Angeles", country: "US").valid?
    assert FilmingLocation.new(name: "Los Angeles", country: "UK").valid?
  end

  test "name and country must be present" do
    assert_not FilmingLocation.new(name: "", country: "US").valid?
    assert_not FilmingLocation.new(name: "LA", country: "").valid?
  end
end
