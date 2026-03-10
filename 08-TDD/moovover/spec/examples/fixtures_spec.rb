# Fixtures demo — Lecture 8, Slides 50–51
#
# Fixtures are YAML files in spec/fixtures/ that Rails loads into the
# test database before each spec.  Good for truly static data.
#
# See: spec/fixtures/movies.yml

require "rails_helper"

RSpec.describe "Fixtures demo", type: :model do
  fixtures :movies

  it "loads the milk_movie fixture by name" do
    movie = movies(:milk_movie)

    expect(movie.title).to eq("Milk")
    expect(movie.rating).to eq("R")
  end

  it "loads the food_inc_movie fixture" do
    movie = movies(:food_inc_movie)

    expect(movie.title).to eq("Food, Inc.")
    expect(movie.release_date).to eq(Date.new(2008, 9, 7))
  end

  it "can use fixture data with model methods" do
    movie = movies(:milk_movie)

    expect(movie.name_with_rating).to eq("Milk (R)")
  end
end
