namespace :data do
  desc "Import movies.csv and reviews.csv into the database (idempotent)"
  task import: :environment do
    result = CsvImporter.new(
      movies_path: Rails.root.join("movies.csv"),
      reviews_path: Rails.root.join("reviews.csv")
    ).call

    puts "Import complete:"
    puts "  movies:            #{result.movies}"
    puts "  actors:            #{result.actors}"
    puts "  filming locations: #{result.filming_locations}"
    puts "  appearances:       #{result.appearances}"
    puts "  reviews:           #{result.reviews}"
  end
end
