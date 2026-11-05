require "csv"

# Idempotently imports movies.csv and reviews.csv into the normalized schema.
#
# movies.csv is denormalized: one row per (movie, actor, filming location).
# This importer deduplicates entities in memory first, then bulk-inserts them
# with `insert_all` against the database's unique indexes (upsert), so running
# it repeatedly is a no-op instead of creating duplicate rows.
class CsvImporter
  Result = Struct.new(
    :movies, :actors, :filming_locations, :appearances, :reviews,
    keyword_init: true
  )

  def initialize(movies_path:, reviews_path:)
    @movies_path = movies_path
    @reviews_path = reviews_path
  end

  def call
    movie_rows = parse_movies
    review_rows = parse_reviews

    movies = dedupe_movies(movie_rows)
    actors = dedupe_actors(movie_rows)
    locations = dedupe_locations(movie_rows)
    appearances = dedupe_appearances(movie_rows)

    insert_movies(movies)
    insert_actors(actors)
    insert_locations(locations)

    # The entities above have just been upserted, so these lookups are complete.
    movie_ids = Movie.pluck(:title, :id).to_h
    actor_ids = Actor.pluck(:name, :id).to_h
    location_ids = FilmingLocation.pluck(:name, :country, :id).each_with_object({}) do |(name, country, id), memo|
      memo[[ name, country ]] = id
    end

    insert_appearances(appearances, movie_ids, actor_ids, location_ids)
    insert_reviews(review_rows, movie_ids)

    Result.new(
      movies: movies.size,
      actors: actors.size,
      filming_locations: locations.size,
      appearances: appearances.size,
      reviews: review_rows.size
    )
  end

  private

  # --- parsing ---------------------------------------------------------------

  def parse_movies
    rows = []
    CSV.foreach(@movies_path, headers: true, encoding: "bom|utf-8") do |row|
      rows << {
        title: row["Movie"].to_s.strip,
        description: row["Description"].to_s.strip,
        year: parse_year(row["Year"]),
        director: row["Director"].to_s.strip,
        actor: row["Actor"].to_s.strip,
        location: row["Filming location"].to_s.strip,
        country: row["Country"].to_s.strip
      }
    end
    rows
  end

  def parse_reviews
    rows = []
    CSV.foreach(@reviews_path, headers: true, encoding: "bom|utf-8") do |row|
      stars = Integer(row["Stars"].to_s.strip)
      raise ArgumentError, "Star rating out of range (1..5): #{stars}" unless (1..5).cover?(stars)

      rows << {
        title: row["Movie"].to_s.strip,
        reviewer: row["User"].to_s.strip,
        stars: stars,
        body: row["Review"].to_s.strip
      }
    end
    rows
  end

  def parse_year(value)
    text = value.to_s.strip
    text.present? ? Integer(text) : nil
  end

  # --- deduplication (the CSV is a cross product) ----------------------------

  def dedupe_movies(rows)
    rows.each_with_object({}) do |row, memo|
      memo[row[:title]] ||= {
        title: row[:title],
        description: row[:description],
        year: row[:year],
        director: row[:director]
      }
    end.values
  end

  def dedupe_actors(rows)
    rows.map { |row| row[:actor] }.uniq
  end

  def dedupe_locations(rows)
    rows.each_with_object({}) do |row, memo|
      key = [ row[:location], row[:country] ]
      memo[key] ||= { name: row[:location], country: row[:country] }
    end.values
  end

  def dedupe_appearances(rows)
    rows.map { |row| [ row[:title], row[:actor], [ row[:location], row[:country] ] ] }.uniq
  end

  # --- inserts (idempotent via unique indexes) --------------------------------

  def insert_movies(movies)
    Movie.insert_all(with_timestamps(movies), unique_by: :title)
  end

  def insert_actors(actors)
    Actor.insert_all(with_timestamps(actors.map { |name| { name: name } }), unique_by: :name)
  end

  def insert_locations(locations)
    FilmingLocation.insert_all(with_timestamps(locations), unique_by: [ :name, :country ])
  end

  def insert_appearances(appearances, movie_ids, actor_ids, location_ids)
    now = Time.current
    rows = appearances.map do |(title, actor, location_key)|
      {
        movie_id: movie_ids.fetch(title),
        actor_id: actor_ids.fetch(actor),
        filming_location_id: location_ids.fetch(location_key),
        created_at: now,
        updated_at: now
      }
    end
    Appearance.insert_all(rows, unique_by: [ :movie_id, :actor_id, :filming_location_id ])
  end

  def insert_reviews(review_rows, movie_ids)
    unknown = review_rows.map { |review| review[:title] }.uniq - movie_ids.keys
    raise ArgumentError, "Reviews reference unknown movies: #{unknown.join(', ')}" if unknown.any?

    now = Time.current
    rows = review_rows.map do |review|
      {
        movie_id: movie_ids.fetch(review[:title]),
        reviewer: review[:reviewer],
        stars: review[:stars],
        body: review[:body],
        created_at: now,
        updated_at: now
      }
    end
    Review.insert_all(rows, unique_by: [ :movie_id, :reviewer ])
  end

  def with_timestamps(rows)
    now = Time.current
    rows.map { |row| row.merge(created_at: now, updated_at: now) }
  end
end
