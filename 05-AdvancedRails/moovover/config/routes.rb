Rails.application.routes.draw do
  root :to => redirect('/movies')

  # Nested RESTful Routes (ESaaS §5.6)
  # Access reviews by going "through" a movie
  # bin/rails routes | grep review to see generated routes
  resources :movies do
    resources :reviews
  end

  # Alternative: explicit routes (commented for reference)
  # get '/movies'          => 'movies#index', as: 'movies'
  # get '/movies/new'      => 'movies#new', as: 'new_movie'
  # post '/movies'         => 'movies#create'
  # get '/movies/:id'      => 'movies#show', as: 'movie'
  # get '/movies/:id/edit' => 'movies#edit', as: 'edit_movie'
  # patch '/movies/:id'    => 'movies#update'
  # delete '/movies/:id'   => 'movies#destroy'

  # Session routes for Single Sign-On (ESaaS §5.2)
  get '/login', to: 'sessions#new', as: 'login'
  delete '/logout', to: 'sessions#destroy', as: 'logout'

  # OmniAuth callback routes
  # OmniAuth adds routes beginning with /auth (ESaaS §5.2)
  get '/auth/:provider/callback', to: 'sessions#create'
  post '/auth/:provider/callback', to: 'sessions#create'
  get '/auth/failure', to: 'sessions#failure'
end
