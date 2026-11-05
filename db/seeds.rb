# Load the CSV data. Idempotent, so it is safe to run repeatedly.
movies_result = MoviesImporter.new(Rails.root.join("movies.csv")).call
reviews_result = ReviewsImporter.new(Rails.root.join("reviews.csv")).call

puts "Seeded #{movies_result.movies} movies, #{movies_result.actors} actors, " \
     "#{movies_result.filming_locations} locations, #{movies_result.appearances} appearances, " \
     "and #{reviews_result.reviews} reviews."

errors = movies_result.errors + reviews_result.errors
if errors.any?
  warn "Skipped #{errors.size} malformed row(s); run bin/rails data:import for details."
end
