# Handout: Code Coverage Deep Dive (ESaaS §8.6, Slides 62–65)

This demo accompanies the **Coverage Lecture** and builds directly on the
TDD & RSpec material from Lecture 8. It uses the same MoovOver Rails app.

By the end of this handout you should be able to:

- Set up SimpleCov to collect line and branch coverage
- Read an HTML coverage report and identify untested code
- Explain the difference between C0 (line) and C1 (branch) coverage
- Use coverage to guide where to write new tests
- Explain why 100% coverage does **not** guarantee correctness

---

## Prerequisites

Complete Exercises 1–3 from the TDD handout (`README.md`), or at least
have the MoovOver project set up with `bundle install` and
`bin/rails db:migrate RAILS_ENV=test` working.

---

## 1. What Is Code Coverage?

Code coverage measures **how much of your source code is executed** when
your test suite runs. It does not measure whether your tests are *good*
— only whether they *touch* certain code.


| Level  | Name              | Question it answers                             |
| ------ | ----------------- | ----------------------------------------------- |
| **C0** | Statement / Line  | Was this line executed at least once?           |
| **C1** | Branch / Decision | Was every branch of every conditional taken?    |
| **C2** | Path              | Was every possible path through the code taken? |


Most tools report C0 by default. C1 is more thorough. C2 is usually
impractical for real codebases.

**Key insight:** Coverage tells you what you did **not** test. It cannot
tell you that what you tested is correct.

---

## 2. Setting Up SimpleCov

SimpleCov is already configured in this project. Here is what was done
(for reference if you want to add it to your own projects):

### 2.1 Gemfile

Two gems were added to the `:test` group:

```ruby
group :test do
  gem "simplecov", require: false
  gem "simplecov-console", require: false
end
```

- `simplecov` — the coverage library. `require: false` because it must
be loaded manually at the very top of the test helper.
- `simplecov-console` — prints a summary table to the terminal.

### 2.2 spec/spec_helper.rb

These lines appear at the **very top** of the file, before any other
`require`:

```ruby
require 'simplecov'
require 'simplecov-console'

SimpleCov.start 'rails' do
  enable_coverage :branch

  add_filter '/spec/'
  add_filter '/config/'
  add_filter '/db/'

  formatter SimpleCov::Formatter::MultiFormatter.new([
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::Console
  ])

  minimum_coverage line: 70, branch: 50
end
```

What each option does:


| Option                    | Purpose                                                            |
| ------------------------- | ------------------------------------------------------------------ |
| `'rails'`                 | Pre-configured profile that knows about Rails directories          |
| `enable_coverage :branch` | Enables C1 branch coverage in addition to C0 line coverage         |
| `add_filter`              | Excludes directories from the report (we only care about app code) |
| `HTMLFormatter`           | Generates `coverage/index.html` — the interactive report           |
| `Console`                 | Prints a summary table to the terminal after each run              |
| `minimum_coverage`        | Fails the test suite if coverage drops below the threshold         |


### 2.3 .gitignore

The `coverage/` directory is gitignored because it is generated output.

---

## 3. Reading the HTML Report

Run the full test suite:

```bash
bundle exec rspec
```

After the run, open the HTML report:

```bash
open coverage/index.html    # macOS
```

### What you will see

1. **Overall summary** — total line coverage %, total branch coverage %,
  number of files, number of lines.
2. **Per-file table** — each file with its line and branch coverage
  percentage. Files are sorted by coverage (lowest first).
3. **File detail view** — click any file name to see source code with
  colored lines:
  - **Green** = executed during tests
  - **Red** = never executed
  - **Dard Red** (branches) = some branches taken, others missed

### Try it now

1. Run `bundle exec rspec` (some specs will fail — that is expected
  if you haven't done Exercises 1–3 yet).
2. Open `coverage/index.html`.
3. Click on `app/models/movie.rb` — notice the red lines for the scopes
  (`for_kids`, `with_good_reviews`, etc.) and for the commented-out
   methods.
4. Click on `app/controllers/movies_controller.rb` — notice that only
  `search_tmdb` has any green (and only if you completed Exercise 3).
   The CRUD actions (`create`, `update`, `destroy`) are entirely red.

---

## 4. C0 vs C1 — Line Coverage vs Branch Coverage

### C0 Example

Consider this method from `movie.rb`:

```ruby
def released_1930_or_later
  return if release_date.blank?
  if release_date < Date.parse('1 Jan 1930')
    errors.add(:release_date, 'must be 1930 or later')
  end
end
```

A test that creates a movie with `release_date: Date.new(1920, 1, 1)`
will execute every line — **100% C0**. But it only tests the path where
the release_date is not blank.

### C1 Example

The same method has **branches**:

- `release_date.blank?` → true (early return) or false (continue)
- `release_date < Date.parse('1 Jan 1930')` → true (add error) or false (skip)

C1 coverage requires tests that exercise **both** sides of each
conditional. The SimpleCov HTML report shows this with dark red highlights
and branch annotations like `[then]` and `[else]`.

### The `grandfathered?` method

```ruby
def grandfathered?
  release_date.present? && release_date < @@grandfathered_date
end
```

This short-circuit `&&` has three meaningful paths:


| `release_date.present?` | `< grandfathered_date` | Result |
| ----------------------- | ---------------------- | ------ |
| false                   | (not evaluated)        | false  |
| true                    | true                   | true   |
| true                    | false                  | false  |


Look at the branch coverage in the HTML report — how many of these
three paths do the existing tests cover?

---

## 5. Hands-On Exercises

### Exercise 4 — Close the Gap: Test a Scope

**File:** `spec/models/movie_coverage_spec.rb`

1. Open `coverage/index.html` and look at `movie.rb`. Find the `for_kids`
  scope — it should be red (uncovered).
2. Open `spec/models/movie_coverage_spec.rb`. You will see a skeleton:
  ```ruby
   describe ".for_kids" do
     # YOUR SPEC HERE
   end
  ```
3. Write a spec that:
  - Creates movies with different ratings (G, PG, R) using
   `create(:movie, ...)` from FactoryBot
  - Calls `Movie.for_kids`
  - Verifies that only G and PG movies are returned
4. Run `bundle exec rspec spec/models/movie_coverage_spec.rb` — your new
  spec should pass.
5. Run `bundle exec rspec` (full suite) and re-open `coverage/index.html`.
  The `for_kids` scope line should now be **green**.

**Hint** (click to reveal)

```ruby
it "returns only G and PG movies" do
  g_movie  = create(:movie, title: "Toy Story", rating: "G")
  pg_movie = create(:movie, title: "Shrek", rating: "PG")
  r_movie  = create(:movie, title: "Alien", rating: "R")

  expect(Movie.for_kids).to contain_exactly(g_movie, pg_movie)
end
```

---

### Exercise 5 — Uncomment Exercises 1–3 and Watch Coverage Jump

This exercise connects the TDD lecture to the coverage lecture.

1. Note the **current** coverage percentage (from the terminal output or
  the HTML report).
2. Complete Exercises 1–3 from the TDD handout:
  - Exercise 1: Uncomment `name_with_rating` in `app/models/movie.rb`
  - Exercise 2: The `find_in_tmdb` seam is already uncommented
  - Exercise 3: Uncomment the body of `search_tmdb` in
  `app/controllers/movies_controller.rb`
3. Run `bundle exec rspec` again.
4. Compare the **new** coverage percentage with the old one.

**What you should observe:**

- Several previously-failing specs now pass (the ones that depend on
`name_with_rating` and `search_tmdb`)
- Line coverage for `movie.rb` and `movies_controller.rb` increases
- The TDD cycle naturally produces coverage: when you write a test first
and then write just enough code to pass it, that code is covered by
definition

---

### Exercise 6 — The False Security Demo

**Code:** `app/models/shipping_calculator.rb`

```ruby
class ShippingCalculator
  def self.cost(weight)
    if weight > 10
      weight * 2.0
    else
      weight * 1.5
    end
  end
end
```

**Spec:** `spec/examples/false_security_spec.rb`

```ruby
it "calculates shipping for a heavy item" do
  expect(ShippingCalculator.cost(15)).to eq(30.0)
end

it "calculates shipping for a light item" do
  expect(ShippingCalculator.cost(5)).to eq(7.5)
end
```

1. Run this spec:
   ```bash
   bundle exec rspec spec/examples/false_security_spec.rb
   ```
   Both tests pass.

2. Open `coverage/index.html` and click on `shipping_calculator.rb`.
   Every line is **green** — 100% line coverage and 100% branch coverage.

3. Now answer: **What happens when `weight == 10`?**
   - Is 10 "heavy" (cost = 20.0) or "light" (cost = 15.0)?
   - The code says `> 10`, so 10 is "light" — but is that correct?
   - The specs never test this boundary, yet coverage is perfect.

4. **Discussion:** Coverage measures **execution**, not **correctness**.
   100% coverage means every line was reached — it does not mean every
   *behavior* was verified. Boundary conditions, off-by-one errors, and
   missing requirements can all hide behind green coverage bars.

**Bonus:** Write a third spec that tests `ShippingCalculator.cost(10)`.
What should the expected value be? You need the *requirements* (not just
the code) to answer this.

---

## 6. Key Takeaways


| Principle                                | Explanation                                                                         |
| ---------------------------------------- | ----------------------------------------------------------------------------------- |
| **Coverage finds what you did NOT test** | It is a diagnostic tool, not a quality guarantee                                    |
| **C0 < C1 < C2**                         | Each level catches more gaps, but costs more effort                                 |
| **100% coverage ≠ bug-free**             | Boundary bugs, logic errors, and missing requirements can hide behind full coverage |
| **Diminishing returns**                  | Going from 80% to 90% is valuable; 95% to 100% often is not worth the effort        |
| **Use `minimum_coverage` as a ratchet**  | Prevent coverage from decreasing as the codebase grows                              |
| **Industry targets**                     | Most teams aim for 80–90% C0; branch coverage targets are usually lower (60–80%)    |
| **TDD gives you coverage for free**      | When you write the test first, the code you add is covered by definition            |


---

## 7. Quick Reference

### Useful commands

```bash
bundle exec rspec                           # run all specs + generate coverage
bundle exec rspec spec/models/              # run only model specs
bundle exec rspec --format documentation    # verbose spec names
open coverage/index.html                    # open HTML coverage report (macOS)
```

### SimpleCov configuration cheat sheet

```ruby
SimpleCov.start 'rails' do
  enable_coverage :branch              # C1 branch coverage
  add_filter '/spec/'                  # exclude test files from report
  add_group 'Models', 'app/models'     # group files in the HTML report
  add_group 'Controllers', 'app/controllers'
  minimum_coverage line: 90, branch: 70  # fail if coverage drops below
  refuse_coverage_drop                 # fail if coverage decreases from last run
end
```

---

## 8. Bonus Exercises

Try these after completing Exercises 4–6:

1. **Test another scope.** Look at `with_good_reviews` in `movie.rb`.
  Write a spec that creates movies with reviews of different ratings and
   verifies the scope filters correctly. Watch the coverage for that
   line turn green.
2. **Explore branch coverage.** Find a dark-red-highlighted line in the
  HTML report (partially covered branches). Write a spec that covers
   the missing branch. Hint: look at `released_1930_or_later` and
   `grandfathered?`.
3. **Raise the bar.** Change `minimum_coverage` in `spec_helper.rb` to
  `line: 80`. Run `bundle exec rspec` — does the suite fail? Write
   enough tests to make it pass again.
4. **Add `refuse_coverage_drop`.** Add this line to the SimpleCov config.
  Now delete a spec file and run again — SimpleCov will refuse to let
   coverage decrease. This is how teams use coverage as a "ratchet" in CI.

