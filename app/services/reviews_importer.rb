# Idempotently imports reviews.csv. Each review is joined to an existing movie
# by title; reviews referencing unknown movies are skipped and reported.
class ReviewsImporter
  include CsvImport

  Result = Struct.new(:reviews, :errors, keyword_init: true)

  def initialize(path)
    @path = path
    validate_columns!(read_header(@path), REVIEWS_COLUMNS, @path)
  end

  def call
    @errors = []

    rows = parse_reviews
    movie_ids = Movie.pluck(:title, :id).to_h
    inserted = insert_reviews(rows, movie_ids)

    Result.new(reviews: inserted, errors: @errors)
  end

  private

  def parse_reviews
    rows = []
    CSV.open(@path, headers: true, encoding: "bom|utf-8") do |csv|
      csv.each do |row|
        data, error = parse_review_row(row)
        if error
          record_error(@path, csv.lineno, error)
        else
          rows << data.merge(line: csv.lineno)
        end
      end
    end
    rows
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

  def insert_reviews(rows, movie_ids)
    now = Time.current
    prepared = rows.filter_map do |review|
      movie_id = movie_ids[review[:title]]
      unless movie_id
        record_error(@path, review[:line], "references unknown movie #{review[:title].inspect}")
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
    Review.insert_all(prepared, unique_by: [ :movie_id, :reviewer ]) if prepared.any?
    prepared.size
  end
end
