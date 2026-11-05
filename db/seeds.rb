# Load the CSV data. Idempotent, so it is safe to run repeatedly.
result = CsvImporter.new(
  movies_path: Rails.root.join("movies.csv"),
  reviews_path: Rails.root.join("reviews.csv")
).call

puts "Seeded #{result.movies} movies, #{result.actors} actors, " \
     "#{result.filming_locations} locations, #{result.appearances} appearances, " \
     "and #{result.reviews} reviews."

if result.errors.any?
  warn "Skipped #{result.errors.size} malformed row(s); run bin/rails data:import for details."
end
