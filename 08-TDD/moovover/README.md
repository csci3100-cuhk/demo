# Handout: BDD with Cucumber and TDD with RSpec (ESaaS §8.1–8.8)

This demo accompanies **Lecture 8 — TDD and RSpec**.
It uses the MoovOver Rails app to walk through the exact examples from the
lecture slides: writing controller specs for a TMDb search feature using
**Red–Green–Refactor**, **seams**, **doubles**, and **stubs**, inside the
Cucumber acceptance-test loop shown on **Slide 6**.

Work through this handout top to bottom. By the end you should be able to
explain how TDD drives the implementation of a new controller action, how
doubles and seams isolate the code under test, and how expectations verify
behavior. You will also see why passing controller specs does not yet mean
that a moviegoer can use the feature through the UI.

---

## Getting Started

```bash
cd moovover
bundle install
bin/rails db:create db:schema:load RAILS_ENV=test
bundle exec cucumber features/search_tmdb.feature  # outer loop: RED first
bundle exec rspec                                  # inner loop: RED too
```

The database command rebuilds the **test database** from the supplied schema.
Use it for initial setup, not between exercises. It does not load the older
demo's seed data; each test supplies its own data.

**Some specs and both Cucumber scenarios are RED on purpose!** This is the
student starting point. Tests are supplied so you can replay test-first
development: observe a meaningful failure, add the smallest implementation,
then rerun. In a new project, you would write these tests before the code.

There are **4 exercises**. Look for comments starting with `EXERCISE`:

| Exercise | File | What to do | Checkpoint |
|----------|------|------------|------------|
| 1 | `app/models/movie.rb` | Uncomment `name_with_rating` (§8 warm-up) | model and fixture/factory specs GREEN |
| 2 | `app/models/movie.rb` | Inspect the already-defined `find_in_tmdb` seam (§3.4) | Understand where tests replace TMDb; no edit needed |
| 3 | `app/controllers/movies_controller.rb` | Uncomment `search_tmdb` action body (§4.4) | all 15 RSpec examples GREEN; Cucumber still RED |
| 4 | `app/views/movies/index.html.erb` | Add the search form (§4.5) | both Cucumber scenarios GREEN |

Follow the handout through §4.5 for the main BDD/TDD walkthrough. Exercise 1
is an independent model warm-up: do §8 before the full-suite checkpoint in
§4.4. The TMDb controller specs do not depend on `name_with_rating`.

After Exercise 3 (and the warm-up), `bundle exec rspec` should report:

```text
15 examples, 0 failures
```

**Do not stop there.** Run Cucumber again: it still fails because the movies
page has no search form. After Exercise 4, run both commands:

```bash
bundle exec rspec
bundle exec cucumber features/search_tmdb.feature
```

Expected final results: **15 examples, 0 failures** and **2 scenarios,
10 steps, all passed**. No TMDb key, network call, running Rails server, or
browser installation is needed. Cucumber uses Capybara's `rack_test` driver
to submit real HTML forms to Rails in-process; it does not execute JavaScript.

---

## 1. Project Structure at a Glance

Below is the directory layout with only the files that matter for this
lecture highlighted. Everything else is standard Rails scaffolding.

```
moovover/
├── features/                                  # ← Cucumber outer BDD loop (§2.2, §4.5)
│   ├── search_tmdb.feature                    #   matching results / no matches
│   ├── step_definitions/tmdb_steps.rb         #   interact with real pages via Capybara
│   └── support/env.rb                        #   Rails, scenario-scoped stubs, DB cleanup
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
│       ├── index.html.erb                     # Exercise 4: add the search form
│       └── search_tmdb.html.erb               # Search Results view
├── config/routes.rb                           # includes search_tmdb route
└── Gemfile                                    # RSpec + FactoryBot + Cucumber Rails
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
that is the inner TDD loop. This tutorial implements the **search slice** of
the story: finding and displaying matches, not importing them into our database.

### 2.1 BDD and TDD: two nested loops (Slide 6)

**BDD (behavior-driven development)** starts with examples of behavior that
users and developers can discuss. Here, Cucumber makes those examples
executable as `Given / When / Then` scenarios. **TDD (test-driven development)**
uses small failing tests to drive the implementation, followed by refactoring.
Here, RSpec tests the controller responsibilities needed by the user scenario.
These practices complement each other; BDD is not merely a final test phase.
Neither practice is restricted to one tool: RSpec can also express behavior
and test integration, as the existing request specs demonstrate.

The sequence on Slide 6 is:

```text
Outer BDD loop:  Cucumber RED ────────────────────────────→ Cucumber GREEN
                     │                                          ↑
                     └→ RSpec RED → implement → RSpec GREEN ──────┘
                            ↑                      │
                            └── refactor / repeat ─┘
```

Write/run the acceptance scenario **first**, but make the supporting RSpec
examples pass **before** expecting the whole user scenario to pass. If
Cucumber is still red, use its failure to identify the missing behavior,
add focused specs where useful, and continue implementation. After refactoring,
rerun both layers.

| Layer in this tutorial | Question answered | What really runs? |
|------------------------|-------------------|-------------------|
| Cucumber + Capybara | Can a moviegoer submit a title and see matches? | HTML form → URL routing → controller → rendered results |
| RSpec controller specs | Does the action call the model, choose the template, and supply results? | Controller action with the TMDb seam stubbed; view rendering disabled by default |

### 2.2 Start with a failing user scenario

**File:** `features/search_tmdb.feature`

```gherkin
Scenario: Find a matching movie
  Given TMDb has a movie titled "Hardware" for the search "hardware"
  And I am on the movies page
  When I search TMDb for "hardware"
  Then I should see the TMDb search results
  And the results should include "Hardware"
```

Run it before implementing anything:

```bash
bundle exec cucumber features/search_tmdb.feature
```

Both scenarios fail at `When I search TMDb ...` with
`Unable to find field "Search Terms"`. That is the expected **outer RED**:
the user cannot search yet. The step definitions already exist, so this is
a missing application behavior, not an undefined Cucumber step.

The second scenario specifies the no-matches message. The `Given` steps
stub **only `Movie.find_in_tmdb`**, returning an unsaved `Movie` or an empty
array. The stub expects the search text as its argument, so a form submitting
the wrong parameter will fail too. We do not stub the controller, route, or
HTML. Both suites therefore verify our app against a controlled TMDb response;
they do **not** prove the real API integration works. The production TMDb
implementation is outside this exercise and still raises if called unstubbed.

The support file resets stubs and rolls back database changes after each
scenario. See the official [Cucumber Rails setup](https://github.com/cucumber/cucumber-rails)
and [stubbing guidance](https://cucumber.io/docs/cucumber/mocking-and-stubbing-with-cucumber/)
for the supporting configuration.

Now leave that acceptance scenario red and enter the smaller RSpec loop.

---

## 3. TDD Setup (Slide 27)

The plumbing below is already present so the controller specs can run
and fail on missing behavior. Exercise 2 is to inspect this setup.

### 3.1 Add a route

**File:** `config/routes.rb`

```ruby
get "/movies/search_tmdb", to: "movies#search_tmdb", as: "search_tmdb_movies"
```

Place this **before `resources :movies`**. Otherwise `/movies/:id` matches
`search_tmdb` as an ID. A controller spec invoking `get :search_tmdb` does not
prove the browser URL reaches that action; Cucumber follows the real route.

### 3.2 Provide the results view

**File:** `app/views/movies/search_tmdb.html.erb` — already displays movie
titles or `No results to display.`. The missing UI for this exercise is the
search form on the movies index page.

### 3.3 Create a placeholder controller action

**File:** `app/controllers/movies_controller.rb`

```ruby
def search_tmdb
  # Exercise 3: leave empty until you have observed the RSpec failures.
end
```

### 3.4 Add the model seam

Calling TMDb is the model's responsibility. The placeholder method is already
defined, but the real API integration is not implemented. This method boundary
is our **seam** — a place we can intercept behavior without changing the
controller code:

**File:** `app/models/movie.rb`

```ruby
def self.find_in_tmdb(_search_terms)
  raise "TMDb search not implemented – this method is intended to be stubbed in tests"
end
```

In both RSpec and Cucumber we **stub** this method so it never raises, and
never calls the real TMDb API. Keep the method defined: verifying partial
doubles reject stubs for nonexistent methods. The seam is the replacement
point; the stub is the replacement behavior installed by a test.

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

### 4.1 Walking through each spec

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

### 4.2 Concepts to notice

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

### 4.3 Inner RED — run the controller specs

```bash
bundle exec rspec spec/controllers/movies_controller_spec.rb
```

With the empty action, expect **3 examples, 2 failures**: the model is not
called and `@movies` is not assigned. The template-selection example already
passes because Rails implicitly renders the template named after the action.
That single green example does not mean the controller is complete.

### 4.4 Inner GREEN — implement the controller (Exercise 3)

Uncomment the supplied body in `app/controllers/movies_controller.rb`:

```ruby
def search_tmdb
  search_terms = params[:search_terms]
  @movies = Movie.find_in_tmdb(search_terms)
  render :search_tmdb
end
```

Run the controller specs again: **3 examples, 0 failures**. The explicit
`render` makes the intent clear for this lesson; Rails could also render
this same-named template implicitly.

Complete the independent `name_with_rating` warm-up in §8 (Exercise 1), then:

```bash
bundle exec rspec
```

You should now see **15 examples, 0 failures**. Refactor if needed and keep
these specs green. This completes the inner loop, not the user story.

### 4.5 Return to the outer loop — connect the UI (Exercise 4)

```bash
bundle exec cucumber features/search_tmdb.feature
```

It still fails with `Unable to find field "Search Terms"`! The controller
specs invoke the action directly and normally do not render the actual view.
They cannot tell us whether a user can find a form, submit it to the right
URL, and see the returned titles.

At the `EXERCISE 4` marker in `app/views/movies/index.html.erb`, add:

```erb
<%= form_with url: search_tmdb_movies_path, method: :get, local: true do |form| %>
  <%= form.label :search_terms, "Search Terms" %>
  <%= form.text_field :search_terms %>
  <%= form.submit "Search TMDb" %>
<% end %>
```

The label makes the field accessible and lets Capybara find it. The GET form
submits `search_terms` to the same action tested by RSpec. The prebuilt results
view renders the assigned movies or the no-matches message.

```bash
bundle exec rspec
bundle exec cucumber features/search_tmdb.feature
```

Now expect **15 examples, 0 failures** and **2 scenarios, 10 steps, all
passed**. The outer loop is GREEN: the search slice works through the UI
against our stubbed service. Both layers must remain green after refactoring.

| Checkpoint | RSpec controller specs | Cucumber | Meaning |
|------------|------------------------|----------|---------|
| Starting code | 2 failures out of 3 | 2 failed scenarios | Controller implementation and search form are missing |
| After Exercise 3 | 3 pass | 2 failed scenarios | Local controller behavior works; the user still cannot search |
| After Exercise 4 | 3 pass | 2 passed scenarios | Form, route, controller, and results view work together |

**Discussion:** temporarily change the form field name to `query` (change
both the label's attribute and the text field), then run both suites.
RSpec stays green; Cucumber fails because the controller reads
`params[:search_terms]` and the stub does not accept `nil`. Restore the name
and rerun. This demonstrates a wiring error that isolated controller specs
cannot catch. Likewise, removing the results list can leave the controller
specs green while the Cucumber result assertion fails.

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
| Admin superuser account | Prefer Fixture (static, shared across tests), but Factory also OK |

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
| **Acceptance** (Cucumber scenarios) | `features/search_tmdb.feature` | Exercises more of the app | Only the external TMDb boundary is stubbed |

From the slides:

- Use **coverage to find untested code**, not as a "100% or bust" rule.
- Each level finds bugs the other misses — defense in depth.

---

## 11. Key Concepts Summary

| Concept | Where you see it in this demo |
|---------|-------------------------------|
| **BDD + TDD (Slide 6)** | Cucumber RED → RSpec RED → RSpec GREEN → Cucumber GREEN (§2.1, §4.3–4.5) |
| **RSpec GREEN ≠ story done** | After Exercise 3, controller specs pass but the user still has no search form |
| **Acceptance criteria** | Cucumber checks matching titles and the no-matches message through the actual UI |
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
