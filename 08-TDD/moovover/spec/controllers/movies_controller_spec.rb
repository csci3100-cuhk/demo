require "rails_helper"

RSpec.describe MoviesController, type: :controller do
  describe "searching TMDb" do
    it "calls the model method that performs TMDb search" do
      expect(Movie).to receive(:find_in_tmdb).with("hardware")

      get :search_tmdb, params: { search_terms: "hardware" }
    end

    it "selects the Search Results template for rendering" do
      allow(Movie).to receive(:find_in_tmdb)

      get :search_tmdb, params: { search_terms: "hardware" }

      expect(response).to render_template("search_tmdb")
    end

    it "makes the TMDb search results available to that template" do
      fake_results = [double("Movie"), double("Movie")]
      allow(Movie).to receive(:find_in_tmdb).and_return(fake_results)

      get :search_tmdb, params: { search_terms: "hardware" }

      expect(assigns[:movies]).to eq(fake_results)
      expect(assigns[:movies]).to be_a_kind_of(Enumerable)
    end
  end
end

