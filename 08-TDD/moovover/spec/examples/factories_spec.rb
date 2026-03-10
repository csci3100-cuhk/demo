# FactoryBot demo — Lecture 8, Slides 52–53
#
# Factories create objects on the fly with sensible defaults.
# sequence (Slide 53) generates unique data per call, keeping
# tests Independent (the "I" in FIRST).
#
# See: spec/factories/movie.rb

require "rails_helper"

RSpec.describe "Factories demo", type: :model do
  it "generates a unique title each time via sequence (Slide 53)" do
    movie_a = build(:movie)
    movie_b = build(:movie)

    expect(movie_a.title).not_to eq(movie_b.title)
  end

  it "overrides factory defaults (Slide 52: name_with_rating)" do
    movie = build(:movie, title: "Milk")

    expect(movie.name_with_rating).to eq("Milk (PG)")
  end

  it "creates a movie saved to the database" do
    movie = create(:movie, title: "Inception", rating: "PG-13")

    expect(movie).to be_persisted
    expect(Movie.find(movie.id).title).to eq("Inception")
  end
end
