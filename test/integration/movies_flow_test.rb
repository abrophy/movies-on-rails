require "test_helper"
require "json"

class MoviesFlowTest < ActionDispatch::IntegrationTest
  setup do
    CsvImporter.new(
      movies_path: Rails.root.join("movies.csv"),
      reviews_path: Rails.root.join("reviews.csv")
    ).call
  end

  test "landing page lists movies sorted by average rating" do
    get root_path
    assert_response :success
    assert_match "Gone in 60 seconds", response.body
    assert_match "Inception", response.body
    assert_operator response.body.index("Gone in 60 seconds"), :<, response.body.index("Inception")
  end

  test "movie page shows cast, locations, and reviews" do
    movie = Movie.find_by(title: "Gone in 60 seconds")
    get movie_path(movie)
    assert_response :success
    assert_match "Nicolas Cage", response.body
    assert_match "Los Angeles", response.body
    assert_match "Sam Pedro", response.body
  end

  test "actor search is case-insensitive" do
    get actors_path(q: "caprio")
    assert_response :success
    assert_match "Leonardo Di Caprio", response.body
    assert_no_match "Nicolas Cage", response.body
  end

  test "actor page lists their movies and locations" do
    actor = Actor.find_by(name: "Leonardo Di Caprio")
    get actor_path(actor)
    assert_response :success
    assert_match "Gone in 60 seconds", response.body
    assert_match "Inception", response.body
  end

  test "location page lists the movies filmed there" do
    location = FilmingLocation.find_by(name: "Los Angeles")
    get location_path(location)
    assert_response :success
    assert_match "Los Angeles", response.body
    assert_match "Gone in 60 seconds", response.body
    assert_match "Inception", response.body
  end

  test "movie page links its filming locations" do
    movie = Movie.find_by(title: "Gone in 60 seconds")
    get movie_path(movie)
    assert_match %r{href="/locations/\d+"}, response.body
  end

  test "api movie list returns sorted json" do
    get api_v1_movies_path
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal [ "Gone in 60 seconds", "Inception" ], json.map { |m| m["title"] }
    assert_in_delta 3.6, json.first["average_rating"], 0.001
  end

  test "api movie show includes nested actors, locations, and reviews" do
    movie = Movie.find_by(title: "Gone in 60 seconds")
    get api_v1_movie_path(movie)
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal "Gone in 60 seconds", json["title"]
    assert_includes json["actors"], "Nicolas Cage"
    assert_equal 5, json["review_count"]
    assert_equal 2, json["filming_locations"].size
  end

  test "api actor show includes movies and locations" do
    actor = Actor.find_by(name: "Leonardo Di Caprio")
    get api_v1_actor_path(actor)
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal [ "Gone in 60 seconds", "Inception" ], json["movies"].map { |m| m["title"] }
  end

  test "api actor index lists all actors when no query" do
    get api_v1_actors_path
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal 5, json.size
  end

  test "api actor search returns matches" do
    get api_v1_actors_path(q: "ribisi")
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal [ "Giovani Ribisi" ], json.map { |a| a["name"] }
  end
end
