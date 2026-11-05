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

    result = begin
      CsvImporter.new(movies_path: movies_path, reviews_path: reviews_path).call
    rescue CsvImporter::InvalidStructureError => e
      abort e.message
    end

    puts "Import complete:"
    puts "  movies:            #{result.movies}"
    puts "  actors:            #{result.actors}"
    puts "  filming locations: #{result.filming_locations}"
    puts "  appearances:       #{result.appearances}"
    puts "  reviews:           #{result.reviews}"

    if result.errors.any?
      warn
      warn "Skipped #{result.errors.size} row(s) with problems:"
      result.errors.each { |error| warn "  #{error[:file]}:#{error[:line]} — #{error[:message]}" }
      warn
    end
  end
end
