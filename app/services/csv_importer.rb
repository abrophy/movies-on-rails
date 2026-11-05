require "csv"

# Idempotently imports movies.csv and reviews.csv into the normalized schema.
#
# movies.csv is denormalized: one row per (movie, actor, filming location).
# This importer deduplicates entities in memory, then bulk-inserts them with
# `insert_all` against the database's unique indexes (upsert), so running it
# repeatedly is a no-op instead of creating duplicate rows.
#
# Safety model — the CSV is treated as untrusted input:
# * Structure: each file's header row must match the expected columns exactly;
#   anything else raises InvalidStructureError before any data is written.
# * Sanitization: values are trimmed and stripped of control characters, and
#   `year`/`stars` are validated by type and range.
# * Injection: all writes go through `insert_all`, which binds values as SQL
#   parameters — no CSV value is ever concatenated into SQL.
# * Row resilience: malformed rows are skipped and reported (file, line, reason);
#   every valid row still imports.
class CsvImporter
  MOVIES_COLUMNS = [ "Movie", "Description", "Year", "Director", "Actor", "Filming location", "Country" ].freeze
  REVIEWS_COLUMNS = [ "Movie", "User", "Stars", "Review" ].freeze

  class InvalidStructureError < StandardError; end

  Result = Struct.new(
    :movies, :actors, :filming_locations, :appearances, :reviews, :errors,
    keyword_init: true
  )

  def initialize(movies_path:, reviews_path:)
    @movies_path = movies_path
    @reviews_path = reviews_path
  end

  def call
    @errors = []

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
    inserted_reviews = insert_reviews(review_rows, movie_ids)

    Result.new(
      movies: movies.size,
      actors: actors.size,
      filming_locations: locations.size,
      appearances: appearances.size,
      reviews: inserted_reviews,
      errors: @errors
    )
  end

  private

  # --- parsing ---------------------------------------------------------------

  def parse_movies
    validate_columns!(read_header(@movies_path), MOVIES_COLUMNS, @movies_path)

    rows = []
    CSV.open(@movies_path, headers: true, encoding: "bom|utf-8") do |csv|
      csv.each do |row|
        data, error = parse_movie_row(row)
        if error
          record_error(@movies_path, csv.lineno, error)
        else
          rows << data
        end
      end
    end
    rows
  end

  def parse_reviews
    validate_columns!(read_header(@reviews_path), REVIEWS_COLUMNS, @reviews_path)

    rows = []
    CSV.open(@reviews_path, headers: true, encoding: "bom|utf-8") do |csv|
      csv.each do |row|
        data, error = parse_review_row(row)
        if error
          record_error(@reviews_path, csv.lineno, error)
        else
          rows << data.merge(line: csv.lineno)
        end
      end
    end
    rows
  end

  def parse_movie_row(row)
    title = clean_text(row["Movie"])
    description = clean_text(row["Description"])
    year_text = clean_text(row["Year"])
    director = clean_text(row["Director"])
    actor = clean_text(row["Actor"])
    location = clean_text(row["Filming location"])
    country = clean_text(row["Country"])

    missing = []
    missing << "Movie" if title.blank?
    missing << "Actor" if actor.blank?
    missing << "Filming location" if location.blank?
    missing << "Country" if country.blank?
    return [ nil, "missing required field(s): #{missing.join(', ')}" ] if missing.any?

    year = nil
    if year_text.present?
      return [ nil, "invalid year #{year_text.inspect}" ] unless year_text.match?(/\A\d+\z/)
      year = year_text.to_i
    end

    [ { title: title, description: description, year: year, director: director, actor: actor, location: location, country: country }, nil ]
  end

  def parse_review_row(row)
    title = clean_text(row["Movie"])
    reviewer = clean_text(row["User"])
    stars_text = clean_text(row["Stars"])
    body = clean_text(row["Review"])

    missing = []
    missing << "Movie" if title.blank?
    missing << "User" if reviewer.blank?
    missing << "Stars" if stars_text.blank?
    return [ nil, "missing required field(s): #{missing.join(', ')}" ] if missing.any?

    unless stars_text.match?(/\A\d\z/) && (1..5).cover?(stars_text.to_i)
      return [ nil, "invalid stars #{stars_text.inspect}" ]
    end

    [ { title: title, reviewer: reviewer, stars: stars_text.to_i, body: body }, nil ]
  end

  # --- structural validation --------------------------------------------------

  # Reads the first row of a CSV (its header) without assuming `headers: true`.
  def read_header(path)
    CSV.open(path, encoding: "bom|utf-8", &:shift)
  end

  def validate_columns!(headers, expected, path)
    actual = Array(headers).map { |header| header.to_s.strip.sub(/^\uFEFF/, "") }
    return if actual == expected

    raise InvalidStructureError,
      "Unrecognized CSV structure in #{File.basename(path.to_s)}: " \
      "expected columns [#{expected.join(', ')}], got [#{actual.join(', ')}]"
  end

  # --- sanitization ------------------------------------------------------------

  # CSV content is untrusted: trim whitespace and drop control characters
  # before use. SQL injection is not possible regardless of content, because
  # every write goes through parameterized `insert_all`.
  def clean_text(value)
    value.to_s.strip.gsub(/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]/, "")
  end

  def record_error(path, line, message)
    @errors << { file: File.basename(path.to_s), line: line, message: message }
  end

  # --- deduplication (the CSV is a cross product) ------------------------------

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

  # --- inserts (idempotent via unique indexes) ----------------------------------

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
    now = Time.current
    rows = review_rows.filter_map do |review|
      movie_id = movie_ids[review[:title]]
      unless movie_id
        record_error(@reviews_path, review[:line], "references unknown movie #{review[:title].inspect}")
        next
      end

      {
        movie_id: movie_id,
        reviewer: review[:reviewer],
        stars: review[:stars],
        body: review[:body],
        created_at: now,
        updated_at: now
      }
    end
    Review.insert_all(rows, unique_by: [ :movie_id, :reviewer ]) if rows.any?
    rows.size
  end

  def with_timestamps(rows)
    now = Time.current
    rows.map { |row| row.merge(created_at: now, updated_at: now) }
  end
end
