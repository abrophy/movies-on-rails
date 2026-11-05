class FilmingLocationsController < ApplicationController
  def show
    @location = FilmingLocation.find(params[:id])
    @movies = @location.movies.order(:title)
  end
end
