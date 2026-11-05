require "rails_helper"

RSpec.describe "Frontend flows", type: :system do
  before do
    MoviesImporter.new(csv_fixture("movies.csv")).call
    ReviewsImporter.new(csv_fixture("reviews.csv")).call
  end

  it "lists movies sorted by average rating on the landing page" do
    visit root_path

    expect(page).to have_content("Gone in 60 seconds")
    expect(page).to have_content("Inception")
    expect(page.body.index("Gone in 60 seconds")).to be < page.body.index("Inception")
  end

  it "navigates from the landing page to a movie page" do
    visit root_path
    click_on "Gone in 60 seconds"

    expect(page).to have_content("Nicolas Cage")
    expect(page).to have_content("Los Angeles")
    expect(page).to have_content("Sam Pedro")
  end

  it "searches for an actor and opens their page" do
    visit root_path
    fill_in "q", with: "caprio"
    click_on "Search"

    expect(page).to have_content("Leonardo Di Caprio")
    click_on "Leonardo Di Caprio"

    expect(page).to have_content("Gone in 60 seconds")
    expect(page).to have_content("Inception")
  end

  it "opens a filming location from a movie page" do
    movie = Movie.find_by(title: "Gone in 60 seconds")
    visit movie_path(movie)
    click_on "Los Angeles"

    expect(page).to have_content("Los Angeles")
    expect(page).to have_content("Gone in 60 seconds")
    expect(page).to have_content("Inception")
  end
end
