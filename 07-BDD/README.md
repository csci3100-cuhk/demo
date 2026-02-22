# Handout: BDD with Cucumber & Capybara (ESaaS §7.6)

This demo accompanies **Lecture 7 — Section 7.6: From Stories to Acceptance Tests**.
It is a minimal Rails app that lists students, used to illustrate the full
Behavior-Driven Design workflow: writing a **user story**, turning it into a
**Cucumber feature**, implementing **step definitions** with **Capybara**, and
watching the Red-Green cycle in action.

Work through this handout top to bottom. By the end you should be able to
explain how a plain-language user story becomes a runnable acceptance test.


---

## Running the Demo

```bash
cd students
bundle config set --local without 'production'
bundle install
bin/rails db:migrate RAILS_ENV=test
bin/rails db:seed     # insert initial students into database
bundle exec cucumber  # run all features
```

You should see output like:

```
Feature: display students in alpha order
  ...
  Scenario: list students in alpha order
    Given student "Alex Lam" exists     # features/step_definitions/student_steps.rb:1
    And student "Shaohua Li" exists      # features/step_definitions/student_steps.rb:1
    When I visit the list of all students # features/step_definitions/student_steps.rb:5
    Then "Alex Lam" should appear before "Shaohua Li" # features/step_definitions/student_steps.rb:9

1 scenario (1 passed)
4 steps (4 passed)
```

All green — the behavior matches the story.

---

## 1. Project Structure at a Glance

Below is the directory layout with only the files that matter for BDD
highlighted. Everything else is standard Rails scaffolding.

```
students/
├── features/                          # ← Cucumber lives here
│   ├── alpha_order.feature            #   the user story / scenarios
│   ├── step_definitions/
│   │   └── student_steps.rb           #   step defs (Ruby + Capybara)
│   └── support/
│       └── env.rb                     #   Cucumber/Capybara bootstrap
├── app/
│   ├── models/student.rb              # ActiveRecord model
│   ├── controllers/students_controller.rb
│   └── views/
│       ├── layouts/application.html.erb
│       └── students/index.html.haml   # the page under test
├── config/routes.rb                   # resources :students
├── db/migrate/..._add_students_table.rb
└── Gemfile                            # test-group gems for Cucumber
```

---

## 2. The User Story (Feature File)

**File:** `features/alpha_order.feature`

```gherkin
Feature: display students in alpha order

  As an instructor
  So that I can quickly find a student in the list
  I want the students to be displayed in alphabetical order by last name

Scenario: list students in alpha order

  Given student "Shaohua Li" exists
  And   student "Alex Lam" exists
  When  I visit the list of all students
  Then  "Alex Lam" should appear before "Shaohua Li"
```

### Concepts to notice

- **Connextra format** — The three-clause header (`As a … / So that … / I want …`)
  captures who the stakeholder is, what their goal is, and what behavior
  supports that goal. This is the "business value" of the feature.

- **Given / When / Then** — These are the three kinds of steps:
  | Keyword | Purpose |
  |---------|---------|
  | **Given** | Set up preconditions (the state of the world before the test) |
  | **When** | Perform an action (simulate what the user does) |
  | **Then** | Check postconditions (verify the expected outcome) |
  | **And / But** | Continue the previous step type |

  Internally, Cucumber treats all five keywords identically — the distinction
  is purely for **readability**.

- **Specificity** — The scenario names *concrete* students ("Shaohua Li",
  "Alex Lam") rather than saying "some student." This is part of making the
  story **Specific** and **Measurable** (the S and M in SMART).

- **One scenario, one behavior** — This scenario tests exactly one thing:
  alphabetical ordering. A different concern (e.g. "what if two students
  share the same last name?") would be a *separate* scenario in the same
  feature file.

---

## 3. Step Definitions — Bridging Plain Language to Code

**File:** `features/step_definitions/student_steps.rb`

```ruby
Given /^student "(.*) (.*)" exists$/ do |first,last|
  Student.create!(:first_name => first, :last_name => last, :sid_number => rand(10000))
end

When /^I visit the list of all students$/ do
  visit students_path
  # save_page
end

Then /^"(.*) (.*)" should appear before "(.*) (.*)"$/ do |first1,last1, first2,last2|
  regex = /#{last1}.*#{first1}.*#{last2}.*#{first2}/
  expect(page.text).to match(regex)
end
```

### How Cucumber matches steps to step defs

Each step in the `.feature` file is matched against the **regular expressions**
in step definition files. Capture groups `(.*)` become block parameters.

```
Scenario step:    Given student "Dorthy Luu" exists
                                 ↓          ↓
Regex:            /^student "(.*) (.*)" exists$/
                             |first| |last|
                                 ↓          ↓
Block params:     first = "Dorthy", last = "Luu"
```

Cucumber loads **all** `*_steps.rb` files; which file a step def lives in
does not matter. Organize by domain concept for maintainability.

### Walking through each step def

#### Step 1 — `Given student "…" exists`

```ruby
Given /^student "(.*) (.*)" exists$/ do |first,last|
  Student.create!(:first_name => first, :last_name => last, :sid_number => rand(10000))
end
```

- Uses ActiveRecord directly (possible because Cucumber, Capybara, and the
  Rails app all run in **one process**).
- `create!` (with bang) raises an exception on failure — desirable in test
  code so failures are loud and obvious.
  student IDs. Only set up what the scenario needs.
- The test database is **wiped clean** before every scenario
  (`database_cleaner` gem), so there is no leftover state between runs.

#### Step 2 — `When I visit the list of all students`

```ruby
When /^I visit the list of all students$/ do
  visit students_path
  # save_page
end
```

- `visit` is a **Capybara** method — it issues an HTTP GET to the given path.
- `students_path` is a Rails route helper (generated by `resources :students`
  in `config/routes.rb`), which resolves to `/students`.
- Using the route helper instead of a hard-coded string decouples the test
  from the URL structure.
- No regex capture groups here because the step has no variable parts.
- You can uncomment `save_page` here to save the visited page into `./tmp/capybara/capybara-xxxxxxx.html`.

#### Step 3 — `Then "…" should appear before "…"`

```ruby
Then /^"(.*) (.*)" should appear before "(.*) (.*)"$/ do |first1,last1, first2,last2|
  regex = /#{last1}.*#{first1}.*#{last2}.*#{first2}/
  expect(page.text).to match(regex)
end
```

- `page` is the central **Capybara** object — it holds the response from
  the most recent request.
- `page.text` strips all HTML tags and returns one flat string of the
  visible text on the page.
- The step constructs a regex like `/Alex.*Lam.*Shaohua.*Li/` and checks
  whether the flattened page text matches it. If `Lam` appears before `Li`
  in the text, the regex matches.
- `expect(…).to match(…)` comes from **RSpec** — Cucumber itself has no
  assertion library; it delegates to RSpec.

---

## 4. The App Under Test

These are standard Rails components. The important thing is how little code
is needed — BDD tests the **behavior** through the UI, not the internal
implementation.

### Model — `app/models/student.rb`

```ruby
class Student < ActiveRecord::Base
end
```

A bare model with no validations. The `students` table has three string
columns: `first_name`, `last_name`, `sid_number`.

### Controller — `app/controllers/students_controller.rb`

```ruby
class StudentsController < ApplicationController
  def index
    @students = Student.all.order(:last_name)
  end
end
```

The `.order(:last_name)` clause is what **makes the scenario pass**. Without
it, students are returned in insertion order and the `Then` step fails.

### View — `app/views/students/index.html.erb`

```erb
<h1>All Students</h1>

<table>
  <thead>
    <tr>
      <th>ID num</th>
      <th>First</th>
      <th>Last</th>
    </tr>
  </thead>
  <tbody>
    <%% @students.each do |student| %>
      <tr>
        <td><%%= student.sid_number %></td>
        <td><%%= student.first_name %></td>
        <td><%%= student.last_name %></td>
      </tr>
    <%% end %>
  </tbody>
</table>
```

The view renders an HTML table. The `page.text` call in the step def
flattens this into a string like `"All Students ID num First Last Alex Lam Shaohua Li"`.

### Route — `config/routes.rb`

```ruby
resources :students
```

This single line generates all seven RESTful routes. The scenario only
exercises the `index` action (`GET /students`).

---

## 5. The BDD Red-Green Cycle

Here is the workflow you should internalize:

```
 ┌─────────────────────────────────────────────────────────┐
 │  1. Write the feature & scenarios (plain language)      │
 │          ↓                                              │
 │  2. Run Cucumber → steps are YELLOW (undefined)         │
 │          ↓                                              │
 │  3. Write step definitions                              │
 │          ↓                                              │
 │  4. Run Cucumber → steps are RED (failing)              │
 │          ↓                                              │
 │  5. Write / fix the application code                    │
 │          ↓                                              │
 │  6. Run Cucumber → steps are GREEN (passing)            │
 │          ↓                                              │
 │  7. Move on to the next scenario or feature             │
 └─────────────────────────────────────────────────────────┘
```

| Color | Meaning |
|-------|---------|
| **Yellow** | No matching step definition found — step is *undefined* |
| **Red** | Step definition exists but the expectation failed — test *fails* |
| **Green** | Step ran and all expectations passed — test *passes* |

In this demo:

1. Without step defs → all steps yellow.
2. With step defs but without `.order(:last_name)` → the `Then` step is red
   because `Shaohua Li` appears before `Alex Lam` in the page text.
3. Adding `.order(:last_name)` to the controller → green.

---

## 6. A Pitfall: False Positives from Insufficient Scoping

Suppose we add a footer to the layout:

```erb
<body>
<%= yield %>
<footer>App by Shaohua Li</footer>
</body>
```

Now even **without** `.order(:last_name)`, the scenario passes — because
`page.text` includes the footer, and `"Shaohua Li"` in the footer appears after
`"Alex Lam"` in the table. This is a **false positive**.

### The fix: scope to a specific element

Give the table an HTML `id`:

```haml
table#students-table
```

Then narrow the step def to look at only the table:

```ruby
Then /^"(.*) (.*)" should appear before "(.*) (.*)"$/ do |first1,last1, first2,last2|
  table = page.find('table#students-table')
  regex = /#{first1}.*#{last1}.*#{first2}.*#{last2}/
  expect(table.text).to match(regex)
end
```

`page.find(css_selector)` returns a Capybara node that behaves just like
`page` but is restricted to that element. Now the footer text is excluded
and the test correctly fails when ordering is missing.

**Takeaway:** Always scope expectations to the narrowest relevant element.
This is one reason to give your HTML elements meaningful `id` and `class`
attributes.

---

## 7. Key Concepts Summary

| Concept | Where you see it in this demo |
|---------|-------------------------------|
| **User story in Connextra format** | The header of `alpha_order.feature` |
| **Given / When / Then** | The scenario steps |
| **Step definitions** | `student_steps.rb` — Ruby blocks keyed by regexes |
| **Regex capture groups → parameters** | `"(.*) (.*)"` captures first and last name |
| **Capybara simulates a browser** | `visit`, `page`, `page.text`, `page.find` |
| **One-process testing stack** | Step defs can call `Student.create!` directly |
| **Database isolation** | `database_cleaner` wipes the test DB before each scenario |
| **Red-Green cycle** | Scenario fails without `.order`, passes with it |
| **Scoping to avoid false positives** | `page.find('table#students-table')` |
| **Domain language** | Steps like `student "…" exists` define a vocabulary specific to this app |

---

## 8. Exercises

Try these modifications to deepen your understanding:

1. **Add a sad-path scenario.** What should happen if no students exist?
   Write a new `Scenario` in `alpha_order.feature` that visits the page with
   an empty database and checks for an appropriate message.

2. **Break the test on purpose.** Remove `.order(:last_name)` from the
   controller. Run `cucumber`. Observe the red output and the diff showing
   what the regex expected vs. what `page.text` contained.

3. **Add the footer pitfall.** Edit `application.html.erb` to include
   `<footer>App by Shaohua Li</footer>`. Run `cucumber` *without* the
   `.order` clause. Observe the false positive. Then apply the scoping fix
   from Section 6 and confirm the test correctly fails again.

4. **Write a new feature.** Create a file `features/student_count.feature`
   with a scenario that verifies the page displays the total number of
   students. You will need to:
   - Write the `.feature` file with Given/When/Then steps.
   - Write new step definitions.
   - Modify the view to display the count.

5. **Declarative vs. imperative.** Rewrite the existing scenario in a more
   *imperative* style (e.g. `When I go to "/students"` instead of
   `When I visit the list of all students`). Which version is easier to
   read? Which is more resilient to URL changes?
