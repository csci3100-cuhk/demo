# MoovOver - Rails Introduction Demo Application

**CSCI3100: Software Engineering - Lecture 4: Rails**

This repository contains a working example of all the Rails concepts covered in the lecture. Use this guide alongside the lecture PDF to explore each concept hands-on.

---

## Table of Contents

1. [Setup Instructions](#setup-instructions)
2. [The Model-View-Controller (MVC) Pattern (ESaaS §4.1)](#1-the-model-view-controller-mvc-pattern-esaas-41)
3. [Rails as an MVC Framework (ESaaS §4.1)](#2-rails-as-an-mvc-framework-esaas-41)
4. [A Trip Through a Rails App (ESaaS §4.1)](#3-a-trip-through-a-rails-app-esaas-41)
5. [Models as Resources (ESaaS §4.2)](#4-models-as-resources-esaas-42)
6. [ActiveRecord: The Glue (ESaaS §4.2)](#5-activerecord-the-glue-esaas-42)
7. [Databases & Migrations (ESaaS §4.2)](#6-databases--migrations-esaas-42)
8. [Controllers & Views (ESaaS §4.4)](#7-controllers--views-esaas-44)
9. [Redirection, Flash and Session (ESaaS §4.4)](#8-redirection-flash-and-session-esaas-44)
10. [Rails Routing Basics (ESaaS §4.4-4.5)](#9-rails-routing-basics-esaas-44-45)
11. [Forms: Creating & Strong Parameters (ESaaS §4.6)](#10-forms-creating--strong-parameters-esaas-46)
12. [Debugging (ESaaS §4.8)](#11-debugging-esaas-48)
13. [Summary & Key Files](#summary--key-files)

---

## Setup Instructions

### Prerequisites
- Ruby 3.3.x
- Rails 7.1.x
- SQLite3

### Installation

```bash
# 1. Install dependencies
bundle install

# 2. Setup database (creates, migrates, and seeds)
./bin/setup

# Or manually:
rails db:create
rails db:migrate
rails db:seed

# 3. Start the Rails server
rails server
```

Visit http://127.0.0.1:3000 to see the application.

### Quick Test
```bash
# Verify everything is working
rails runner "puts 'Movies: ' + Movie.count.to_s"
```

---

## 1. The Model-View-Controller (MVC) Pattern (ESaaS §4.1)

**Lecture Slides: 6-8**

MVC is a design pattern that separates concerns:

| Component | Responsibility |
|-----------|----------------|
| **Model** | Data & business logic (what is stored, operations on data) |
| **View** | Presentation (what the user sees and interacts with) |
| **Controller** | Mediator (handles user input, updates model, selects view) |

### What MVC Does NOT Specify

- How or where the model state is stored
- The technology or nature of the "connections" among M, V, and C

### From Sinatra to Rails

In Sinatra, everything is in `app.rb`. In Rails:
- **Routes** are in `config/routes.rb`
- **Controllers** are in `app/controllers/`
- **Models** are in `app/models/`
- **Views** are in `app/views/`

---

## 2. Rails as an MVC Framework (ESaaS §4.1)

**Lecture Slides: 9-12**

### Rails Request Flow

```
1. HTTP request arrives
2. Routing (config/routes.rb) parses URL, identifies controller action
3. Controller action is called
4. Model state is stored/updated in database
5. View is rendered
6. Response sent to browser
```

### Key Insight

> **Everything is stateless except the database!**

### Directory Structure

```
your_app/
├── app/
│   ├── controllers/     # Subclasses of ApplicationController
│   ├── models/          # Subclasses of ApplicationRecord (ActiveRecord)
│   └── views/           # ERB templates
├── config/
│   └── routes.rb        # URL routing
└── db/
    ├── migrate/         # Database migrations
    └── schema.rb        # Current database schema
```

---

## 3. A Trip Through a Rails App (ESaaS §4.1)

**Lecture Slides: 13-15**

Let's trace a request through our MoovOver app:

### Step 1: Route Matching

**File: `config/routes.rb`**

```ruby
get '/movies/:id' => 'movies#show', as: 'movie'
```

When you visit `/movies/1`:
- Rails matches the route `get '/movies/:id'`
- Extracts `params[:id] = "1"`
- Calls `MoviesController#show`

### Step 2: Controller Action

**File: `app/controllers/movies_controller.rb`**

```ruby
def show
  # @movie is set by before_action :set_movie
end

private

def set_movie
  @movie = Movie.find(params[:id])
end
```

The controller:
- Uses `params[:id]` to find the movie
- Sets `@movie` instance variable (visible to view)
- The method `set_movie` is called before every other method in the `movie_controller.rb`. You can will learn this in the next lecture. 

### Step 3: View Rendering

**File: `app/views/movies/show.html.erb`**

```erb
<%= render @movie %>
```

By convention, Rails looks for `app/views/movies/show.html.erb`.

### Rails Philosophy

| Principle | Description |
|-----------|-------------|
| **Convention over Configuration** | Follow naming conventions, no config files needed |
| **Don't Repeat Yourself (DRY)** | Extract common functionality |

Example: `MoviesController#show` automatically renders `views/movies/show.html.erb`

#### Try It

1. Visit http://127.0.0.1:3000/movies/1
2. Check the Rails server log to see the routing and rendering

---

## 4. Models as Resources (ESaaS §4.2)

**Lecture Slides: 16-20**

### Resource ⬄ Model

| Question | Answer |
|----------|--------|
| What can you do to a resource? | CRUD (Create, Read, Update, Delete) |
| How to name resource & operation? | Routes |
| How to inspect/modify resource? | Views & Controllers |
| Where does resource state live? | Model persisted in database |

### Models and Databases

| Concept | Database Equivalent |
|---------|---------------------|
| Collection of instances | Database table |
| One instance | One row |
| Attribute of model | Database column |
| Class & instance methods | Model logic |

### CRUD Operations in SQL

Rails generates SQL at runtime based on your Ruby code:

(You don't need to master these SQL queries, but it's good to know how they look like.)

| Operation | SQL |
|-----------|-----|
| Create | `INSERT INTO movies (title, rating) VALUES (...)` |
| Read | `SELECT * FROM movies WHERE id = 1` |
| Update | `UPDATE movies SET rating = 'PG' WHERE id = 1` |
| Delete | `DELETE FROM movies WHERE id = 1` |

---

## 5. ActiveRecord: The Glue (ESaaS §4.2)

**Lecture Slides: 21-30**

### The Ruby Side of a Model

**File: `app/models/movie.rb`**

```ruby
class Movie < ApplicationRecord
end
```

By subclassing `ApplicationRecord`:
- The model is "connected" to the database
- Table name is derived from class name: `Movie` → `movies`
- Column names become getter/setter methods

### CRUD with ActiveRecord

#### Create

```ruby
# new creates object in memory (not saved yet)
movie = Movie.new(title: 'Coco', rating: 'PG')
movie.new_record?  # => true
movie.save         # saves to database

# create combines new and save
movie = Movie.create(title: 'Coco', rating: 'PG')

# create! raises exception on failure
movie = Movie.create!(title: 'Coco', rating: 'PG')
```

#### Read (Find)

```ruby
# Find by primary key (raises exception if not found)
Movie.find(3)

# Find with conditions
Movie.where("rating = 'PG'")
Movie.where("rating = ?", 'PG')  # Safe from SQL injection!
Movie.where(rating: 'PG')        # Even better

# DANGEROUS - SQL injection vulnerability!
Movie.where("rating = '#{rating}'")  # DON'T DO THIS!

# Chaining queries (lazy evaluation)
kiddie = Movie.where("rating = 'G'")
old_kids = kiddie.where("release_date < ?", 30.years.ago)
```

#### Update

```ruby
# Find and modify
movie = Movie.find(1)
movie.rating = 'PG-13'
movie.save

# Or use update
movie.update(rating: 'PG-13')

# update is transactional: all attributes updated or none
```

#### Delete (Destroy)

```ruby
movie = Movie.find(1)
movie.destroy

# After destroy, object is still in memory but can't be modified
movie.title = 'New Title'  # FAILS!
```

#### Try It - Rails Console

```bash
rails console
```

```ruby
# List all movies
Movie.all

# Find a specific movie
movie = Movie.find_by(title: 'Aladdin')
movie.rating

# Create a new movie
new_movie = Movie.create!(title: 'Test Movie', rating: 'PG', release_date: '01 Jan 2024')
new_movie.id  # => assigned by database

# Update it
new_movie.update(rating: 'G')

# Destroy it
new_movie.destroy

# Query with conditions
Movie.where(rating: 'R').pluck(:title)
```

### Important: Object in Memory ≠ Row in Database

- `save` must be called to persist changes
- `destroy` doesn't delete the in-memory object

---

## 6. Databases & Migrations (ESaaS §4.2)

**Lecture Slides: 33-37**

### Why Migrations?

> **Your customer data is golden!**

Migrations provide:
- **Automation** - scripts can be versioned and replicated
- **Safety** - avoid manual database changes
- **Collaboration** - team members can apply the same changes

### Three Environments

Rails has separate databases for:

| Environment | Purpose |
|-------------|---------|
| **development** | Local development |
| **test** | Automated testing |
| **production** | Live application |

### Creating Migrations

```bash
# Generate a migration
rails generate migration CreateMovies

# This creates a file in db/migrate/
# Edit the file to define your schema changes

# Apply migrations
rails db:migrate
```

**File: `db/migrate/20260127035328_add_stars_to_movie.rb`**

```ruby
class AddStarsToMovie < ActiveRecord::Migration[7.1]
  def change
    change_table :movies do |t|
      t.integer :stars
    end
  end
end
```

### Migration Commands

```bash
# Run pending migrations
rails db:migrate

# Rollback last migration
rails db:rollback

# Check migration status
rails db:migrate:status

# Reset database (drop, create, migrate, seed)
rails db:reset
```

### Rails Cookery: Adding a New Model

1. Create migration: `rails generate migration CreateMovies`
2. Edit migration file to define columns
3. Apply migration: `rails db:migrate`
4. Create model file: `app/models/movie.rb`

---

## 7. Controllers & Views (ESaaS §4.4)

**Lecture Slides: 38-40**

### MVC Responsibilities

| Component | Example |
|-----------|---------|
| **Model** | `Movie.where(...)`, `Movie.find(...)` |
| **Controller** | Get data, make available to view |
| **View** | Display data, allow user interaction |

### Controller Instance Variables

Instance variables (with `@`) set in controllers are automatically available in views:

**File: `app/controllers/movies_controller.rb`**

```ruby
def index
  @movies = Movie.all  # Available in view as @movies
end

def show
  # @movie is set by before_action :set_movie
end
```

### View Naming Convention

By default, Rails looks for:
```
app/views/{controller_name}/{action_name}.html.erb
```

For `MoviesController#show`: `app/views/movies/show.html.erb`

### Rails Cookery: Adding a New Action

1. Create route in `config/routes.rb`
2. Add action in `app/controllers/*_controller.rb`
3. Create view in `app/views/model/action.html.erb`

---

## 8. Redirection, Flash and Session (ESaaS §4.4)

**Lecture Slides: 41-43**

### The Problem

After creating a movie, what view should be rendered?
- Redirect user to a more useful page (e.g., list of movies)
- But how to inform user about the result?

### The Flash

`flash[]` is a hash that persists until the end of the **next request** only.

**File: `app/controllers/movies_controller.rb`**

```ruby
def create
  @movie = Movie.new(movie_params)
  if @movie.save
    redirect_to @movie, notice: "Movie was successfully created."
  else
    render :new, status: :unprocessable_entity
  end
end
```

### Flash Conventions

| Key | Usage |
|-----|-------|
| `:notice` | Informational messages (success) |
| `:alert` | Warning/error messages |

### Displaying Flash in Layout

**File: `app/views/layouts/application.html.erb`**

```erb
<% if flash[:notice].to_s != '' %>
<div class="alert alert-info">
  <%= flash[:notice] %>
</div>
<% end %>
```

### flash vs flash.now

| Method | When to Use |
|--------|-------------|
| `flash[:notice]` | With `redirect_to` (next request) |
| `flash.now[:notice]` | With `render` (current request) |

#### Try It

1. Create a new movie at http://127.0.0.1:3000/movies/new
2. Notice the flash message after successful creation
3. Refresh the page - the message disappears (one-time only!)

### The Root Route

**File: `config/routes.rb`**

```ruby
root :to => redirect('/movies')
```

Visit http://127.0.0.1:3000/ and you'll be redirected to the movies list.

---

## 9. Rails Routing Basics (ESaaS §4.4-4.5)

**Lecture Slides: 44-48**

### RESTful Route Conventions

| Operation | HTTP Method | URI Pattern | Action |
|-----------|-------------|-------------|--------|
| Index | GET | /movies | `movies#index` |
| Create | POST | /movies | `movies#create` |
| New | GET | /movies/new | `movies#new` |
| Show | GET | /movies/:id | `movies#show` |
| Edit | GET | /movies/:id/edit | `movies#edit` |
| Update | PATCH/PUT | /movies/:id | `movies#update` |
| Delete | DELETE | /movies/:id | `movies#destroy` |

### Our Routes File

**File: `config/routes.rb`**

```ruby
Rails.application.routes.draw do
  root :to => redirect('/movies')

  get '/movies'          => 'movies#index', as: 'movies'
  get '/movies/new'      => 'movies#new', as: 'new_movie'
  post '/movies'         => 'movies#create'
  get '/movies/:id'      => 'movies#show', as: 'movie'
  get '/movies/:id/edit' => 'movies#edit', as: 'edit_movie'
  patch '/movies/:id'    => 'movies#update'
  delete '/movies/:id'   => 'movies#destroy'

  # All of the above can be replaced with:
  # resources :movies
end
```

### Path Helper Methods

The `as:` option creates path helper methods:

| Helper | Returns |
|--------|---------|
| `movies_path` | `/movies` |
| `movie_path(5)` | `/movies/5` |
| `new_movie_path` | `/movies/new` |
| `edit_movie_path(5)` | `/movies/5/edit` |

### Viewing Routes

```bash
# See all routes
rails routes

# Filter routes
rails routes | grep movie
```

#### Try It

```bash
rails routes
```

Output:
```
    Prefix Verb   URI Pattern              Controller#Action
    movies GET    /movies(.:format)        movies#index
           POST   /movies(.:format)        movies#create
 new_movie GET    /movies/new(.:format)    movies#new
     movie GET    /movies/:id(.:format)    movies#show
edit_movie GET    /movies/:id/edit(.:format) movies#edit
           PATCH  /movies/:id(.:format)    movies#update
           DELETE /movies/:id(.:format)    movies#destroy
```

---

## 10. Forms: Creating & Strong Parameters (ESaaS §4.6)

**Lecture Slides: 49-56**

### Two-Step Form Process

Creating/editing a resource usually takes 2 interactions:

| Step | Action | Purpose |
|------|--------|---------|
| 1 | `new` / `edit` | Retrieve and display the form |
| 2 | `create` / `update` | Submit and process the form |

### Form Helper

**File: `app/views/movies/_form.html.erb`**

```erb
<%= form_with(model: movie) do |form| %>
  <% if movie.errors.any? %>
    <div style="color: red">
      <h2><%= pluralize(movie.errors.count, "error") %> prohibited this movie from being saved:</h2>
      <ul>
        <% movie.errors.each do |error| %>
          <li><%= error.full_message %></li>
        <% end %>
      </ul>
    </div>
  <% end %>

  <div>
    <%= form.label :title %>
    <%= form.text_field :title %>
  </div>

  <div>
    <%= form.label :rating %>
    <%= form.text_field :rating %>
  </div>

  <%= form.submit %>
<% end %>
```

### Form Parameters

When submitted, form fields become nested in `params`:

```ruby
params = {
  "movie" => {
    "title" => "The Matrix",
    "rating" => "R",
    "description" => "...",
    "release_date" => "1999-03-31"
  }
}
```

### Strong Parameters

> **"The controller decides which form field parameters are allowed"**

This prevents mass assignment vulnerabilities:

**File: `app/controllers/movies_controller.rb`**

```ruby
private

def movie_params
  params.require(:movie).permit(:title, :rating, :description, :release_date)
end
```

Without `permit`, Rails will raise an error if you try to use `params[:movie]` directly for mass assignment.

### Using Strong Parameters

```ruby
def create
  @movie = Movie.new(movie_params)  # Uses permitted params only
  if @movie.save
    redirect_to @movie, notice: "Movie was successfully created."
  else
    render :new
  end
end

def update
  if @movie.update(movie_params)
    redirect_to @movie, notice: "Movie was successfully updated."
  else
    render :edit
  end
end
```

### New vs Edit

| Aspect | New/Create | Edit/Update |
|--------|------------|-------------|
| Form pre-filled? | No | Yes (existing values) |
| HTTP method | POST | PATCH/PUT |
| Model object | `Movie.new` | `Movie.find(params[:id])` |

---

## 11. Debugging (ESaaS §4.8)

**Lecture Slides: 57-63**

### Debugging Challenges

> **Errors early in flow may manifest much later:**
> URI → route → controller → model → view → render

### Debugging Techniques

| Technique | Development | Production |
|-----------|-------------|------------|
| Printf debugging | ✓ | ✗ |
| `rails console` | ✓ | ✓ |
| Interactive debugger | ✓ | ✗ |
| Logging | ✓ | ✓ |

### RASP: When Stuck

1. **R**ead the error message. Really read it.
2. **A**sk a colleague an informed question.
3. **S**earch (StackOverflow, Google, etc.)
4. **P**ost on forums with minimal but complete information.

### Common Error: undefined method for nil:NilClass

```ruby
@m = Movie.find_by(id: nonexistent_id)  # Returns nil if not found
@m.title  # ERROR: undefined method 'title' for nil:NilClass
```

### Instrumentation

In views:
```erb
<%= debug(@movie) %>
<%= @movie.inspect %>
```

In controllers:
```ruby
logger.debug(@movie.inspect)
```

> **Warning:** Avoid `puts` or `printf` - they have nowhere to go in production!

### Rails Console

```bash
rails console
```

Interactive REPL to test code:

```ruby
Movie.find(1)
Movie.where(rating: 'PG').count
Movie.create(title: 'Test', rating: 'G', release_date: '2024-01-01')
```

---

## Summary & Key Files

### Sinatra vs Rails Comparison

| Aspect | Sinatra | Rails |
|--------|---------|-------|
| App structure | Single `app.rb` | MVC directories |
| Routes | Inline: `post '/new_game' do...end` | Separate `config/routes.rb` |
| Naming | Arbitrary | Convention over configuration |
| Database | Manual | ActiveRecord + migrations |
| Environments | Single | Development, test, production |
| Start app | `rackup` | `rails server` |

### Concept-to-File Mapping

| Concept | Lecture Section | File(s) |
|---------|-----------------|---------|
| Routes | §4.4-4.5 | `config/routes.rb` |
| Controller | §4.4 | `app/controllers/movies_controller.rb` |
| Model | §4.2 | `app/models/movie.rb` |
| Views | §4.4 | `app/views/movies/*.html.erb` |
| Forms | §4.6 | `app/views/movies/_form.html.erb` |
| Flash | §4.4 | `app/views/layouts/application.html.erb` |
| Migrations | §4.2 | `db/migrate/*.rb` |
| Schema | §4.2 | `db/schema.rb` |
| Seeds | §4.2 | `db/seeds.rb` |

### Quick Reference Commands

```bash
# Start server
rails server

# Open Rails console
rails console

# View all routes
rails routes

# Run database migrations
rails db:migrate

# Reset database (drop, create, migrate, seed)
rails db:reset

# Generate a migration
rails generate migration AddColumnToTable

# View schema
cat db/schema.rb
```

### Common Pitfalls

| Pitfall | Description |
|---------|-------------|
| **Fat Controllers** | Putting too much logic in controllers instead of models |
| **Fat Views** | Putting loops, sorting, conditionals in views |
| **SQL Injection** | Using string interpolation in queries: `Movie.where("rating='#{rating}'")` |
| **Forgetting save** | Creating objects but not persisting them |
| **nil errors** | Not checking if `find_by` returns nil |

---

## Exercises for Students

### Exercise 1: Add a New Attribute
Add a `director` field to the Movie model:
1. Generate a migration
2. Apply it
3. Update the form to include the new field
4. Update strong parameters

### Exercise 2: Use `resources :movies`
Replace the explicit routes in `config/routes.rb` with `resources :movies`. Verify the routes are the same with `rails routes`.

### Exercise 3: Custom Query
In `rails console`, write a query to find all R-rated movies released before 2000.

### Exercise 4: Flash Variations
Modify the destroy action to use `:alert` instead of `:notice`. Update the layout to display alerts differently.

---

## Additional Resources

- [Rails Guides: Getting Started](https://guides.rubyonrails.org/getting_started.html)
- [Rails Guides: Active Record Basics](https://guides.rubyonrails.org/active_record_basics.html)
- [Rails Guides: Action Controller Overview](https://guides.rubyonrails.org/action_controller_overview.html)
- [Rails Guides: Routing](https://guides.rubyonrails.org/routing.html)
- [Rails API Documentation](https://api.rubyonrails.org/)
- [ESaaS Textbook Chapter 4](https://www.saasbook.info/)
