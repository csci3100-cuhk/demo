require "rails_helper"

RSpec.describe "Movies", type: :request do
  describe "GET /movies/:id" do
    let!(:movie) { Movie.create!(title: "Inception", rating: "PG-13", release_date: Date.new(2010, 7, 16)) }

    it "responds with HTML for regular requests" do
      get movie_path(movie)

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/html")
    end

    it "returns JSON for .json requests" do
      get movie_path(movie, format: :json)

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["id"]).to eq(movie.id)
      expect(json["title"]).to eq("Inception")
      expect(json["rating"]).to eq("PG-13")
    end
  end
end

