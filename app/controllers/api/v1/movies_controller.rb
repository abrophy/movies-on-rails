module Api
  module V1
    class MoviesController < ApplicationController
      def index
        movies = Movie.ordered_by_rating
        render json: movies.map { |movie| summary(movie) }
      end

      def show
        movie = Movie.find(params[:id])
        reviews = movie.reviews

        render json: {
          id: movie.id,
          title: movie.title,
          description: movie.description,
          year: movie.year,
          director: movie.director,
          average_rating: average_of(reviews),
          review_count: reviews.size,
          actors: movie.actors.order(:name).pluck(:name),
          filming_locations: movie.filming_locations.order(:name).map do |location|
            { name: location.name, country: location.country }
          end,
          reviews: reviews.order(:created_at, :id).map do |review|
            { reviewer: review.reviewer, stars: review.stars, body: review.body }
          end
        }
      end

      private

      # Used by #index, where average_rating/review_count are computed columns.
      def summary(movie)
        {
          id: movie.id,
          title: movie.title,
          year: movie.year,
          director: movie.director,
          average_rating: movie.average_rating.round(2),
          review_count: movie.review_count
        }
      end

      def average_of(reviews)
        reviews.any? ? reviews.sum(&:stars).fdiv(reviews.size).round(2) : 0.0
      end
    end
  end
end
