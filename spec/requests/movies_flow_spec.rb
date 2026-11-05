require "rails_helper"
require "json"

RSpec.describe "Movies flow", type: :request do
  before do
    MoviesImporter.new(csv_fixture("movies.csv")).call
    ReviewsImporter.new(csv_fixture("reviews.csv")).call
  end

  describe "HTML pages" do
    it "lists movies sorted by average rating on the landing page" do
      get root_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Gone in 60 seconds")
      expect(response.body).to include("Inception")
      expect(response.body.index("Gone in 60 seconds")).to be < response.body.index("Inception")
    end

    it "shows cast, locations, and reviews on the movie page" do
      movie = Movie.find_by(title: "Gone in 60 seconds")
      get movie_path(movie)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Nicolas Cage")
      expect(response.body).to include("Los Angeles")
      expect(response.body).to include("Sam Pedro")
    end

    it "searches actors case-insensitively" do
      get actors_path(q: "caprio")

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Leonardo Di Caprio")
      expect(response.body).not_to include("Nicolas Cage")
    end

    it "lists an actor's movies and locations" do
      actor = Actor.find_by(name: "Leonardo Di Caprio")
      get actor_path(actor)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Gone in 60 seconds")
      expect(response.body).to include("Inception")
    end

    it "lists the movies filmed at a location" do
      location = FilmingLocation.find_by(name: "Los Angeles")
      get location_path(location)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Los Angeles")
      expect(response.body).to include("Gone in 60 seconds")
      expect(response.body).to include("Inception")
    end

    it "links filming locations from the movie page" do
      movie = Movie.find_by(title: "Gone in 60 seconds")
      get movie_path(movie)

      expect(response.body).to match(%r{href="/locations/\d+"})
    end

    it "treats SQL injection in search literally" do
      before = Actor.count
      get actors_path(q: "'; DROP TABLE actors; --")

      expect(response).to have_http_status(:success)
      expect(response.body).to include("No actors match")
      expect(Actor.count).to eq(before)
    end
  end

  describe "JSON API" do
    it "returns movies sorted by average rating" do
      get api_v1_movies_path

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json.map { |m| m["title"] }).to eq([ "Gone in 60 seconds", "Inception" ])
      expect(json.first["average_rating"]).to be_within(0.001).of(3.6)
    end

    it "returns a movie with nested actors, locations, and reviews" do
      movie = Movie.find_by(title: "Gone in 60 seconds")
      get api_v1_movie_path(movie)

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json["title"]).to eq("Gone in 60 seconds")
      expect(json["actors"]).to include("Nicolas Cage")
      expect(json["review_count"]).to eq(5)
      expect(json["filming_locations"].size).to eq(2)
    end

    it "returns an actor with their movies and locations" do
      actor = Actor.find_by(name: "Leonardo Di Caprio")
      get api_v1_actor_path(actor)

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json["movies"].map { |m| m["title"] }).to eq([ "Gone in 60 seconds", "Inception" ])
    end

    it "lists all actors when no query is given" do
      get api_v1_actors_path

      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body).size).to eq(5)
    end

    it "searches actors by name" do
      get api_v1_actors_path(q: "ribisi")

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json.map { |a| a["name"] }).to eq([ "Giovani Ribisi" ])
    end

    it "returns a location with its movies" do
      location = FilmingLocation.find_by(name: "Los Angeles")
      get api_v1_location_path(location)

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json["name"]).to eq("Los Angeles")
      expect(json["movies"].map { |m| m["title"] }).to eq([ "Gone in 60 seconds", "Inception" ])
    end

    it "returns JSON 404 for an unknown id" do
      get api_v1_movie_path(id: 999_999)

      expect(response).to have_http_status(:not_found)
      expect(JSON.parse(response.body)).to eq({ "error" => "not_found" })
    end
  end
end
