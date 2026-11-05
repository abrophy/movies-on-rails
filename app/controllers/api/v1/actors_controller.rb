module Api
  module V1
    class ActorsController < BaseController
      def index
        actors = params[:q].present? ? Actor.search(params[:q]) : Actor.all
        render json: actors.order(:name).map { |actor| { id: actor.id, name: actor.name } }
      end

      def show
        actor = Actor.find(params[:id])
        render json: {
          id: actor.id,
          name: actor.name,
          movies: actor.movies.order(:title).map { |movie| { id: movie.id, title: movie.title, year: movie.year } },
          filming_locations: actor.filming_locations.order(:name).map do |location|
            { id: location.id, name: location.name, country: location.country }
          end
        }
      end
    end
  end
end
