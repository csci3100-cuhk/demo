require "rails_helper"

RSpec.describe "Doubles and seams" do
  it "uses a stunt double for a Movie-like object" do
    award = double("Award", type: "Oscar")
    director = double("Director", name: "JJ Abrams")
    movie = double("Movie", title: "Snowden", award: award, director: director)

    expect(movie.title).to eq("Snowden")
    expect(movie.award.type).to eq("Oscar")
    expect(movie.director.name).to eq("JJ Abrams")
  end
end

