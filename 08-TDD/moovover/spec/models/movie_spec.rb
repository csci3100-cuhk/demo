require "rails_helper"

RSpec.describe Movie, type: :model do
  describe "#name_with_rating" do
    it "returns 'Title (RATING)' for a movie" do
      movie = Movie.new(title: "Milk", rating: "PG", release_date: Date.new(2008, 11, 26))

      expect(movie.name_with_rating).to eq("Milk (PG)")
    end
  end

  describe "validations" do
    it "is invalid without a title" do
      movie = Movie.new(release_date: Date.new(2000, 1, 1))

      expect(movie).not_to be_valid
      expect(movie.errors[:title]).to be_present
    end

    it "is invalid with release_date before 1930" do
      movie = Movie.new(title: "Oldie", release_date: Date.new(1920, 1, 1))

      expect(movie).not_to be_valid
      expect(movie.errors[:release_date]).to be_present
    end
  end
end

