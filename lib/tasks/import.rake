namespace :data do
  desc "Import movie and review CSVs (idempotent). " \
       "Set MOVIES and REVIEWS to target specific files (absolute or Rails-root-relative)."
  task import: :environment do
    movies = Pathname(ENV.fetch("MOVIES", "movies.csv"))
    reviews = Pathname(ENV.fetch("REVIEWS", "reviews.csv"))

    movies_path = movies.absolute? ? movies : Rails.root.join(movies)
    reviews_path = reviews.absolute? ? reviews : Rails.root.join(reviews)

    abort "Movies file not found: #{movies_path}" unless movies_path.exist?
    abort "Reviews file not found: #{reviews_path}" unless reviews_path.exist?

    movies_importer = MoviesImporter.new(movies_path)
    reviews_importer = ReviewsImporter.new(reviews_path)
  rescue CsvImport::InvalidStructureError => e
    abort e.message
  else
    movies_result = movies_importer.call
    reviews_result = reviews_importer.call

    puts "Import complete:"
    puts "  movies:            #{movies_result.movies}"
    puts "  actors:            #{movies_result.actors}"
    puts "  filming locations: #{movies_result.filming_locations}"
    puts "  appearances:       #{movies_result.appearances}"
    puts "  reviews:           #{reviews_result.reviews}"

    errors = movies_result.errors + reviews_result.errors
    if errors.any?
      warn
      warn "Skipped #{errors.size} row(s) with problems:"
      errors.each { |error| warn "  #{error[:file]}:#{error[:line]} — #{error[:message]}" }
      warn
    end
  end
end
