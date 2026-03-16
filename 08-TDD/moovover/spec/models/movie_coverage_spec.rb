require "rails_helper"

RSpec.describe Movie, type: :model do
  # ============================================================
  # EXERCISE 4: Close the Gap — Test a Scope
  # ============================================================
  # Open coverage/index.html and look at movie.rb.
  # The `for_kids` scope (line 34) is RED — never executed by any test.
  #
  # Your task:
  #   1. Write a spec that creates movies with different ratings
  #      (G, PG, R, etc.) using FactoryBot's `create` helper.
  #   2. Call Movie.for_kids and verify only G and PG movies are returned.
  #   3. Run `bundle exec rspec` and re-open coverage/index.html —
  #      the scope line should now be GREEN.
  #
  # Hints:
  #   - Scopes query the database, so you must use `create(:movie, ...)`
  #     (not `build`) to persist records.
  #   - The `contain_exactly` matcher checks that two collections have
  #     the same elements regardless of order.
  # ============================================================
  describe ".for_kids" do
    # YOUR SPEC HERE
    
    # it "returns only G and PG movies" do
    #   g_movie  = create(:movie, title: "Toy Story", rating: "G")
    #   pg_movie = create(:movie, title: "Shrek", rating: "PG")
    #   r_movie  = create(:movie, title: "Alien", rating: "R")

    #   expect(Movie.for_kids).to contain_exactly(g_movie, pg_movie)
    # end
  end
end
