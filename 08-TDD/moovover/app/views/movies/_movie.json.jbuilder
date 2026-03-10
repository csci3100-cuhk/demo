# ESaaS §6.7 - AJAX: JSON response for movie data
# When JS calls $.ajax({ url: '/movies/1.json' }), this template
# renders the movie as JSON. The JS callback (MoviePopup.showMovieData)
# unpacks this JSON and updates the DOM.
#
# render json: @movie would call to_json (ESaaS §6.7),
# but jbuilder gives us more control over the JSON structure.
json.extract! movie, :id, :title, :rating, :description, :release_date, :created_at, :updated_at
json.url movie_url(movie, format: :json)
json.review_count movie.reviews.count
