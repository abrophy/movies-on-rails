Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions.
  get "up" => "rails/health#show", as: :rails_health_check

  # HTML pages
  root "movies#index"
  resources :movies, only: [ :index, :show ]
  resources :actors, only: [ :index, :show ]
  get "locations/:id", to: "filming_locations#show", as: :location

  # JSON API
  namespace :api do
    namespace :v1 do
      resources :movies, only: [ :index, :show ]
      resources :actors, only: [ :index, :show ]
    end
  end
end
