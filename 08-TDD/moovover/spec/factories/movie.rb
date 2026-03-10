# Factory from Lecture 8 (Slides 52–53)
#
# Usage in specs (with FactoryBot::Syntax::Methods included):
#   build(:movie)              → Movie.new (not saved to DB)
#   create(:movie)             → Movie.create! (saved to DB)
#   build(:movie, title: 'Milk')  → override defaults
#
# sequence (Slide 53) ensures each call produces a unique title,
# so tests stay Independent (the "I" in FIRST).

FactoryBot.define do
  factory :movie do
    sequence(:title) { |n| "Film #{n}" }
    rating { "PG" }
    release_date { Date.new(2020, 1, 1) }
  end
end
