module Api
  module V1
    class LocationsController < BaseController
      def show
        location = FilmingLocation.find(params[:id])
        render json: {
          id: location.id,
          name: location.name,
          country: location.country,
          movies: location.movies.order(:title).map { |movie| { id: movie.id, title: movie.title, year: movie.year } }
        }
      end
    end
  end
end
