# Idempotently imports the denormalized movies.csv (one row per
# movie × actor × filming location) into movies, actors, filming_locations,
# and appearances.
class MoviesImporter
  include CsvImport

  Result = Struct.new(:movies, :actors, :filming_locations, :appearances, :errors, keyword_init: true)

  def initialize(path)
    @path = path
    validate_columns!(read_header(@path), MOVIES_COLUMNS, @path)
  end

  def call
    @errors = []

    rows = parse_movies

    movies = dedupe_movies(rows)
    actors = dedupe_actors(rows)
    locations = dedupe_locations(rows)
    appearances = dedupe_appearances(rows)

    insert_movies(movies)
    insert_actors(actors)
    insert_locations(locations)

    # These entities have just been upserted, so the lookups are complete.
    movie_ids = Movie.pluck(:title, :id).to_h
    actor_ids = Actor.pluck(:name, :id).to_h
    location_ids = FilmingLocation.pluck(:name, :country, :id).each_with_object({}) do |(name, country, id), memo|
      memo[[ name, country ]] = id
    end

    insert_appearances(appearances, movie_ids, actor_ids, location_ids)

    Result.new(
      movies: movies.size,
      actors: actors.size,
      filming_locations: locations.size,
      appearances: appearances.size,
      errors: @errors
    )
  end

  private

  def parse_movies
    rows = []
    CSV.open(@path, headers: true, encoding: "bom|utf-8") do |csv|
      csv.each do |row|
        data, error = parse_movie_row(row)
        if error
          record_error(@path, csv.lineno, error)
        else
          rows << data
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
end
