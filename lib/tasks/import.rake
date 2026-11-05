namespace :data do
  desc "Import the movie CSV (idempotent). Set MOVIES to target a specific file (absolute or Rails-root-relative)."
  task import_movies: :environment do
    path = import_path(ENV.fetch("MOVIES", "movies.csv"))
    abort "Movies file not found: #{path}" unless path.exist?

    result = run_import(MoviesImporter, path)
    print_import_result(
      "movies" => result.movies,
      "actors" => result.actors,
      "filming locations" => result.filming_locations,
      "appearances" => result.appearances
    )
    print_import_errors(result.errors)
  end

  desc "Import the review CSV (idempotent). Set REVIEWS to target a specific file. Movies must already be imported."
  task import_reviews: :environment do
    path = import_path(ENV.fetch("REVIEWS", "reviews.csv"))
    abort "Reviews file not found: #{path}" unless path.exist?

    result = run_import(ReviewsImporter, path)
    print_import_result("reviews" => result.reviews)
    print_import_errors(result.errors)
  end

  desc "Import both CSVs in order: movies, then reviews (idempotent)."
  task import: [ :import_movies, :import_reviews ]
end

def import_path(value)
  path = Pathname(value)
  path.absolute? ? path : Rails.root.join(path)
end

def run_import(importer_class, path)
  importer_class.new(path).call
rescue CsvImport::InvalidStructureError => e
  abort e.message
end

def print_import_result(counts)
  puts "Import complete:"
  counts.each { |label, count| puts format("  %-18s %s", "#{label}:", count) }
end

def print_import_errors(errors)
  return if errors.empty?

  warn
  warn "Skipped #{errors.size} row(s) with problems:"
  errors.each { |error| warn "  #{error[:file]}:#{error[:line]} — #{error[:message]}" }
  warn
end
