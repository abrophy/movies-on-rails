class MoviesController < ApplicationController
  def index
    @movies = Movie.ordered_by_rating
  end

  def show
    @movie = Movie.find(params[:id])
    @actors = @movie.actors.order(:name)
    @locations = @movie.filming_locations.order(:name)
    @reviews = @movie.reviews.order(:created_at, :id)
    @average_rating = @reviews.any? ? @reviews.sum(&:stars).fdiv(@reviews.size) : 0.0
  end
end
