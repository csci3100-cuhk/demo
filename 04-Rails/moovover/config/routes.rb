Rails.application.routes.draw do
  root :to => redirect('/movies')

  get '/movies'          => 'movies#index', as: 'movies'
  get '/movies/new'      => 'movies#new', as: 'new_movie'
  post '/movies'         => 'movies#create'
  get '/movies/:id'      => 'movies#show', as: 'movie'
  get '/movies/:id/edit' => 'movies#edit', as: 'edit_movie'
  patch '/movies/:id'    => 'movies#update'
  delete '/movies/:id'   => 'movies#destroy'

  # resources :movies

end
