require "rails_helper"

RSpec.describe FilmingLocation, type: :model do
  it "requires name to be unique within a country" do
    FilmingLocation.create!(name: "Los Angeles", country: "US")

    expect(FilmingLocation.new(name: "Los Angeles", country: "US")).not_to be_valid
    expect(FilmingLocation.new(name: "Los Angeles", country: "UK")).to be_valid
  end

  it "requires name and country" do
    expect(FilmingLocation.new(name: "", country: "US")).not_to be_valid
    expect(FilmingLocation.new(name: "LA", country: "")).not_to be_valid
  end
end
