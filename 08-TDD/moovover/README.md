# Handout: TDD and RSpec (ESaaS §8.1–8.8)

This demo accompanies **Lecture 8 — TDD and RSpec**.
It uses the MoovOver Rails app to walk through the exact examples from the
lecture slides: writing controller specs for a TMDb search feature using
**Red–Green–Refactor**, **seams**, **doubles**, and **stubs**.

Work through this handout top to bottom. By the end you should be able to
explain how TDD drives the implementation of a new controller action, how
doubles and seams isolate the code under test, and how expectations verify
behavior.

---

## Getting Started

```bash
cd moovover
bundle install
bin/rails db:migrate RAILS_ENV=test
bundle exec rspec           # run all specs
```

**Some specs are RED on purpose!** Key implementation code has been
commented out. Your job is to find and uncomment the right code to turn
each exercise from RED to GREEN — just like the TDD cycle in the lecture.

There are **3 exercises** spread across 2 files. Look for comments that
start with `EXERCISE`:

| Exercise | File | What to uncomment | Specs that turn GREEN |
|----------|------|-------------------|----------------------|
| 1 | `app/models/movie.rb` | `name_with_rating` method | model spec, fixture/factory specs |
| 2 | `app/models/movie.rb` | `find_in_tmdb` class method (the seam) | — (needed by Exercise 3) |
| 3 | `app/controllers/movies_controller.rb` | `search_tmdb` action body | all 3 controller specs |

Work through them in order (1 → 2 → 3). After each exercise, run
`bundle exec rspec` to see specs go from RED to GREEN.

When all exercises are done you should see:

```
...............

Finished in 0.12 seconds
15 examples, 0 failures
```

---

## 1. Project Structure at a Glance

Below is the directory layout with only the files that matter for this
lecture highlighted. Everything else is standard Rails scaffolding.

```
moovover/
├── spec/                                      # ← RSpec lives here
│   ├── controllers/
│   │   └── movies_controller_spec.rb          #   TMDb search controller spec (§4)
│   ├── models/
│   │   └── movie_spec.rb                      #   model specs: name_with_rating, validations (§8–9)
│   ├── requests/
│   │   └── movies_spec.rb                     #   request-level spec: HTML vs JSON (§10)
│   ├── examples/
│   │   ├── doubles_spec.rb                    #   standalone doubles example (§6)
│   │   ├── fixtures_spec.rb                   #   fixtures demo (§7)
│   │   └── factories_spec.rb                  #   FactoryBot demo (§7)
│   ├── fixtures/
│   │   └── movies.yml                         #   fixture data from Slides 50–51
│   ├── factories/
│   │   └── movie.rb                           #   factory definition from Slide 52
│   ├── rails_helper.rb
│   └── spec_helper.rb
├── app/
│   ├── models/movie.rb                        # Movie model with find_in_tmdb seam
│   ├── controllers/movies_controller.rb       # search_tmdb action
│   └── views/movies/
│       └── search_tmdb.html.erb               # Search Results view
├── config/routes.rb                           # includes search_tmdb route
└── Gemfile                                    # rspec-rails + factory_bot_rails
```

---

## 2. The Feature: Look Up Movie in TMDb (ESaaS §8.3, Slides 20–23)

The lecture introduces a new user story:

> **Feature:** look up movie in TMDb  
> **As** a lazy moviegoer  
> **So that** I can add movies without filling in info manually  
> **I want** to look up a movie by title in TMDb

The controller needs to do three things ("the code you wish you had"):

1. **Call a model method** that searches TMDb for the specified movie.
2. **Render** a "Search Results" view if matches are found.
3. **Make the results available** to that view.

We will test all three behaviors *before* we write the controller code —
that is TDD.

---

## 3. TDD Setup (Slide 27)

The slides say: before writing any specs, set up the plumbing so the test
can at least *run* (even if it fails):

### 3.1 Add a route

**File:** `config/routes.rb`

```ruby
get "/movies/search_tmdb", to: "movies#search_tmdb", as: "search_tmdb_movies"
```

### 3.2 Create an empty view

**File:** `app/views/movies/search_tmdb.html.erb` — exists so the
controller can render *something*.

### 3.3 Create a placeholder controller action

**File:** `app/controllers/movies_controller.rb`

```ruby
def search_tmdb
  search_terms = params[:search_terms]
  @movies = Movie.find_in_tmdb(search_terms)
  render :search_tmdb
end
```

### 3.4 Add the model seam

Calling TMDb is the model's responsibility, but the real method does not
exist yet. We add a **seam** — a place we can intercept behavior without
changing app code:

**File:** `app/models/movie.rb`

```ruby
def self.find_in_tmdb(_search_terms)
  raise "TMDb search not implemented – this method is intended to be stubbed in tests"
end
```

In the specs we will **stub** this method so it never raises, and never
calls the real TMDb API.

---

## 4. The Controller Spec — Three Behaviors (Slides 25–33, 39)

**File:** `spec/controllers/movies_controller_spec.rb`

```ruby
require 'rails_helper'

RSpec.describe MoviesController, type: :controller do
  describe 'searching TMDb' do
    it 'calls the model method that performs TMDb search' do
      expect(Movie).to receive(:find_in_tmdb).with('hardware')

      get :search_tmdb, params: { search_terms: 'hardware' }
    end

    it 'selects the Search Results template for rendering' do
      allow(Movie).to receive(:find_in_tmdb)

      get :search_tmdb, params: { search_terms: 'hardware' }

      expect(response).to render_template('search_tmdb')
    end

    it 'makes the TMDb search results available to that template' do
      fake_results = [double('Movie'), double('Movie')]
      allow(Movie).to receive(:find_in_tmdb).and_return(fake_results)

      get :search_tmdb, params: { search_terms: 'hardware' }

      expect(assigns[:movies]).to eq(fake_results)
      expect(assigns[:movies]).to be_a_kind_of(Enumerable)
    end
  end
end
```

### Walking through each spec

#### Spec 1 — "calls the model method" (Slide 30)

```ruby
expect(Movie).to receive(:find_in_tmdb).with('hardware')
get :search_tmdb, params: { search_terms: 'hardware' }
```

- `expect(Movie).to receive(:find_in_tmdb)` is a **message expectation**
  (mock). It tells RSpec: "this spec should **fail** unless the controller
  calls `Movie.find_in_tmdb` with the argument `'hardware'` before the spec
  finishes."
- `get :search_tmdb` simulates submitting the search form to the controller
  action.
- The expectation line comes *before* the `get` — RSpec sets up the
  expectation first, then checks it after the action runs.

#### Spec 2 — "selects the Search Results template" (Slides 25, 33)

```ruby
allow(Movie).to receive(:find_in_tmdb)
get :search_tmdb, params: { search_terms: 'hardware' }
expect(response).to render_template('search_tmdb')
```

- `allow` is a **method stub** — it intercepts the call to
  `find_in_tmdb` and returns `nil`, preventing the real (unimplemented)
  method from raising an error.
- `render_template('search_tmdb')` (Slide 25) verifies the controller
  rendered the correct view template. This matcher comes from the
  `rails-controller-testing` gem.
- Note the difference: `expect(...).to receive` = "this **must** be called"
  (mock); `allow(...).to receive` = "if called, return this" (stub).

#### Spec 3 — "makes results available to the template" (Slides 25, 39)

```ruby
fake_results = [double('Movie'), double('Movie')]
allow(Movie).to receive(:find_in_tmdb).and_return(fake_results)
get :search_tmdb, params: { search_terms: 'hardware' }
expect(assigns[:movies]).to eq(fake_results)
expect(assigns[:movies]).to be_a_kind_of(Enumerable)
```

- `double('Movie')` creates a **stunt double** — a fake object that
  stands in for a real `Movie`. We don't care about its attributes here;
  we just need something the view can iterate over.
- `assigns[:movies]` (Slide 25) is a hash of all instance variables set
  by the controller — `assigns[:movies]` reads `@movies`. This comes from
  the `rails-controller-testing` gem.
- `be_a_kind_of(Enumerable)` (Slide 25) checks that the results are
  iterable, which is all the view needs to loop over them.
- `and_return(fake_results)` makes the stub return our fake list.
- We verify that the controller set `@movies` to exactly the fake results.
  This is how the view will access the data.

### Concepts to notice

| Concept | Where you see it |
|---------|-----------------|
| **Seam** | `Movie.find_in_tmdb` — we intercept it without changing the controller |
| **Method stub** (`allow`) | Intercepts `find_in_tmdb` so it doesn't hit TMDb |
| **Message expectation** (`expect...to receive`) | Verifies the controller *actually calls* the model method |
| **Stunt double** (`double`) | Fake Movie objects returned by the stub |
| **`render_template`** (Slide 25) | Checks which view template the controller rendered |
| **`assigns[:movies]`** (Slide 25) | Reads the `@movies` instance variable set by the controller |
| **`be_a_kind_of`** (Slide 25) | Checks the results are Enumerable (iterable by the view) |
| **Arrange–Act–Assert** | Each spec: set up stub → call controller → check result |

---

## 5. Great Expectations — RSpec Matchers (Slides 17–18)

The specs above use several RSpec matchers. Here is a quick reference
from the slides:

```ruby
expect(x).to eq('Ruby')             # equality
expect(x).to be_truthy              # truthy value
expect(x).to match(/regex/)         # regex match
expect(x).to have_key('key')        # hash key
expect(x).to be_empty               # empty collection
expect(x).to be_valid               # implicitly calls x.valid?

expect { movie.save! }.to raise_error
expect { review.destroy }.to change { Review.count }.by(-1)
```

---

## 6. Stunt Doubles & the Mock Trainwreck Pitfall (Slides 38, 56)

**File:** `spec/examples/doubles_spec.rb`

```ruby
RSpec.describe 'Doubles and seams' do
  it 'uses a stunt double for a Movie-like object' do
    award = double('Award', type: 'Oscar')
    director = double('Director', name: 'JJ Abrams')
    movie = double('Movie', title: 'Snowden', award: award, director: director)

    expect(movie.title).to eq('Snowden')
    expect(movie.award.type).to eq('Oscar')
    expect(movie.director.name).to eq('JJ Abrams')
  end
end
```

From the slides:

- `double('Movie')` creates a bare stand-in.
- `double('Movie', title: 'Snowden')` adds canned responses.
- `allow(m).to receive(:title).and_return('Snowden')` is the longer form.
- **Pitfall — mock trainwreck (slide 56):** chaining many doubles
  (`movie.award.type`, `movie.director.name`) can make tests fragile and
  tightly coupled to the internal structure of your objects. Use doubles
  sparingly.

---

## 7. Fixtures & Factories (Slides 49–53)

### When you need the real thing (Slide 49)

Sometimes a double is not enough — you need a real ActiveRecord object.
The slides describe two approaches. **Both are included in this demo** so
you can run them yourself.

### Approach A — Fixtures: static YAML data (Slides 50–51)

> Fixtures are YAML files that Rails loads into the test database before
> each spec. Good for truly static data that never changes.

**File:** `spec/fixtures/movies.yml`

```yaml
milk_movie:
  id: 1
  title: Milk
  rating: R
  release_date: 2008-11-26

food_inc_movie:
  id: 2
  title: "Food, Inc."
  release_date: 2008-09-07
```

**File:** `spec/examples/fixtures_spec.rb` — run with
`bundle exec rspec spec/examples/fixtures_spec.rb`

```ruby
RSpec.describe "Fixtures demo", type: :model do
  fixtures :movies

  it "loads the milk_movie fixture by name" do
    movie = movies(:milk_movie)

    expect(movie.title).to eq("Milk")
    expect(movie.rating).to eq("R")
  end

  it "can use fixture data with model methods" do
    movie = movies(:milk_movie)

    expect(movie.name_with_rating).to eq("Milk (R)")
  end
end
```

### Approach B — Factories: create what you need per-test (Slides 52–53)

> Factories (via the `factory_bot_rails` gem) generate objects on the fly.
> `sequence` (Slide 53) ensures each call produces unique data — keeping
> tests **Independent** (the "I" in FIRST).

**File:** `spec/factories/movie.rb`

```ruby
FactoryBot.define do
  factory :movie do
    sequence(:title) { |n| "Film #{n}" }
    rating { "PG" }
    release_date { Date.new(2020, 1, 1) }
  end
end
```

Every call to `build(:movie)` increments `n`, producing `"Film 1"`,
`"Film 2"`, `"Film 3"`, etc. — no two tests share the same title.

**File:** `spec/examples/factories_spec.rb` — run with
`bundle exec rspec spec/examples/factories_spec.rb`

```ruby
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
```

### `build` vs `create`

| Method | What it does | Hits DB? |
|--------|-------------|----------|
| `build(:movie)` | `Movie.new(...)` with factory defaults | No |
| `create(:movie)` | `Movie.create!(...)` with factory defaults | Yes |

Use `build` when you only need an in-memory object (faster).
Use `create` when the test needs the record to exist in the database.

### When to use fixtures vs factories?

| Data | Fixture or Factory? |
|------|-------------------|
| TMDb API key | Fixture (static config that never changes) |
| Movie for a specific test | Factory (create per-test with custom attributes) |
| Admin superuser account | Fixture (static, shared across tests) |

---

## 8. Red–Green–Refactor: `Movie#name_with_rating` (Slides 7, 49, 52)

This is a small standalone example showing the TDD cycle on a model
method. The slides reference `name_with_rating` in the Fixtures &
Factories section.

### 8.1 RED — write the spec first

**File:** `spec/models/movie_spec.rb`

```ruby
describe '#name_with_rating' do
  it "returns 'Title (RATING)' for a movie" do
    movie = Movie.new(title: 'Milk', rating: 'PG', release_date: Date.new(2008, 11, 26))

    expect(movie.name_with_rating).to eq('Milk (PG)')
  end
end
```

Run it:

```bash
bundle exec rspec spec/models/movie_spec.rb:4
```

It fails with `NoMethodError: undefined method 'name_with_rating'` — **RED**.

### 8.2 GREEN — simplest code to pass

**File:** `app/models/movie.rb`

```ruby
def name_with_rating
  "#{title} (#{rating})"
end
```

Run again → **GREEN**.

### 8.3 REFACTOR — nothing to clean up

The implementation is already minimal. Move on to the next behavior.

---

## 9. FIRST — Properties of Good Unit Tests (Slides 12–13)

The model validation specs illustrate FIRST:

**File:** `spec/models/movie_spec.rb`

```ruby
describe 'validations' do
  it 'is invalid without a title' do
    movie = Movie.new(release_date: Date.new(2000, 1, 1))
    expect(movie).not_to be_valid
    expect(movie.errors[:title]).to be_present
  end

  it 'is invalid with release_date before 1930' do
    movie = Movie.new(title: 'Oldie', release_date: Date.new(1920, 1, 1))
    expect(movie).not_to be_valid
    expect(movie.errors[:release_date]).to be_present
  end
end
```

| Letter | Property | How this spec satisfies it |
|--------|----------|--------------------------|
| **F** | Fast | No DB writes — `Movie.new` only |
| **I** | Independent | Each spec creates its own `Movie` |
| **R** | Repeatable | No randomness or time-of-day dependency |
| **S** | Self-checking | `expect` automatically passes or fails |
| **T** | Timely | Written alongside the validations |

---

## 10. Coverage & the Testing Pyramid (Slides 62–65)

| Level | Example in this demo | Speed | Mocks? |
|-------|---------------------|-------|--------|
| **Unit** (model specs) | `spec/models/movie_spec.rb` | Fastest | Few/none |
| **Functional** (controller specs) | `spec/controllers/movies_controller_spec.rb` | Fast | Stubs & doubles |
| **Integration** (request specs) | `spec/requests/movies_spec.rb` | Slower | None |

From the slides:

- Use **coverage to find untested code**, not as a "100% or bust" rule.
- Each level finds bugs the other misses — defense in depth.

---

## 11. Key Concepts Summary

| Concept | Where you see it in this demo |
|---------|-------------------------------|
| **Red–Green–Refactor** | `name_with_rating`: spec fails → add method → spec passes |
| **The code you wish you had** | `Movie.find_in_tmdb` — tested before implemented |
| **Seam** | `Movie.find_in_tmdb` is the place we intercept without changing the controller |
| **Method stub** (`allow`) | `allow(Movie).to receive(:find_in_tmdb)` returns canned data |
| **Message expectation** (`expect...to receive`) | Verifies the controller calls `find_in_tmdb` |
| **Stunt double** (`double`) | `fake_results = [double('Movie'), double('Movie')]` |
| **FIRST** | All model specs are fast, independent, repeatable, self-checking, timely |
| **Arrange–Act–Assert** | Every spec: setup → action → expectation |
| **Fixtures vs Factories** | Lecture examples shown in Section 7 |
| **Coverage levels** | Unit / Functional / Integration pyramid |

---

## 12. Hands-On Exercises (Red → Green)

The implementation code is **commented out** in the source files.
Work through the exercises in order. After each one, run
`bundle exec rspec` and observe specs turning from RED to GREEN.

### Exercise 1 — Model TDD: `name_with_rating`

1. Run `bundle exec rspec spec/models/movie_spec.rb` — observe the failure:
   `NoMethodError: undefined method 'name_with_rating'`
2. Open `app/models/movie.rb`, find the `EXERCISE 1` comment, and
   **uncomment** the `name_with_rating` method.
3. Run the spec again — it should be GREEN.

**What you learned:** This is the Red–Green cycle. The spec existed first
(the code you wish you had), then you added the implementation.

### Exercise 2 — Add the Seam: `find_in_tmdb`

1. Run `bundle exec rspec spec/controllers/movies_controller_spec.rb` —
   observe: `Movie does not implement: find_in_tmdb`
2. Open `app/models/movie.rb`, find the `EXERCISE 2` comment, and
   **uncomment** the `find_in_tmdb` class method.
3. Run the controller spec again — the error message changes (but specs
   still fail). This is progress! The seam now exists, but the controller
   doesn't use it yet.

**What you learned:** A seam is a method you can intercept (stub) without
changing the code that calls it. The method doesn't need a real
implementation — it just needs to *exist* so RSpec can stub it.

### Exercise 3 — Controller TDD: `search_tmdb` action

1. Open `app/controllers/movies_controller.rb`, find the `EXERCISE 3`
   comment, and **uncomment** the three lines inside `search_tmdb`.
2. Run `bundle exec rspec spec/controllers/movies_controller_spec.rb` —
   all 3 specs should be GREEN.

**What you learned:** The controller action does three things that match
the three specs: (1) calls `Movie.find_in_tmdb`, (2) renders the
`search_tmdb` template, (3) assigns `@movies` for the view.

### Verify: all GREEN

```bash
bundle exec rspec
# 15 examples, 0 failures
```

### Bonus Exercises

Try these after completing Exercises 1–3:

1. **Re-comment the controller body** (Exercise 3) and run specs. Read
   each failure message — can you match each failure to a specific `it`
   block?

2. **Add a sad-path spec.** What should happen if `find_in_tmdb` returns
   `[]`? Write a new `it` block that stubs it to return `[]` and checks
   the response.

3. **Break a stub on purpose.** In spec 1, change `'hardware'` to
   `'software'` in `with('hardware')`. Run it and read the mismatch
   message.

4. **Add a model spec for a scope.** Write a spec for `Movie.for_kids`
   that creates movies with different ratings and checks only G and PG
   are returned.
