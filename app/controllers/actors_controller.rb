class ActorsController < ApplicationController
  def index
    @query = params[:q].to_s.strip
    @actors = Actor.search(@query).order(:name)
  end

  def show
    @actor = Actor.find(params[:id])
    @movies = @actor.movies.order(:title)
    @locations = @actor.filming_locations.order(:name)
  end
end
