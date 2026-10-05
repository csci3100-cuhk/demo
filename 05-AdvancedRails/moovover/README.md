# MoovOver - Advanced Rails Demo Application

**CSCI3100: Software Engineering - Lecture 5: Advanced Rails**

This repository contains a complete working example of all the advanced Rails concepts covered in the lecture. Use this guide alongside the lecture PDF to explore each concept hands-on.

---

## Table of Contents

1. [Setup Instructions](#setup-instructions)
2. [DRYing Out MVC (ESaaS §5.1)](#1-drying-out-mvc-esaas-51)
   - [Model Validations](#11-model-validations)
   - [Controller Filters](#12-controller-filters)
   - [Partials](#13-partials)
3. [Single Sign-On & Third-Party Authentication (ESaaS §5.2)](#2-single-sign-on--third-party-authentication-esaas-52)
4. [ActiveRecord Associations (ESaaS §5.3)](#3-activerecord-associations-esaas-53)
5. [Associations & Foreign Keys (ESaaS §5.4)](#4-associations--foreign-keys-esaas-54)
6. [Through-Associations (ESaaS §5.5)](#5-through-associations-esaas-55)
7. [RESTful Routes for Associations (ESaaS §5.6)](#6-restful-routes-for-associations-esaas-56)
8. [Referential Integrity](#7-referential-integrity)
9. [DRYing Out Queries with Scopes (ESaaS §5.8)](#8-drying-out-queries-with-scopes-esaas-58)
10. [Summary & Key Files](#summary--key-files)

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
rails runner "puts 'Movies: ' + Movie.count.to_s; puts 'Moviegoers: ' + Moviegoer.count.to_s; puts 'Reviews: ' + Review.count.to_s"
```

---

## 1. DRYing Out MVC (ESaaS §5.1)

The DRY (Don't Repeat Yourself) principle is central to Rails. Cross-cutting concerns are handled through:
- **Validations** - for models
- **Controller Filters** - for controllers  
- **Partials** - for views

### 1.1 Model Validations

> *"Goal: enforce that movie names must be less than 40 characters"*

Validations are specified declaratively in model classes. They act as "advice" in the Aspect-Oriented Programming sense.

**File: `app/models/movie.rb`**

```ruby
class Movie < ApplicationRecord
  # Validations (ESaaS §5.1)
  validates :title, presence: true, length: { maximum: 40 }
  validates :rating, inclusion: { in: %w[G PG PG-13 R NC-17],
                                  message: '%{value} is not a valid rating' },
                     allow_blank: true
end
```

#### Try It - Rails Console

```bash
rails console
```

```ruby
# Test presence validation
movie = Movie.new(title: nil)
movie.valid?                    # => false
movie.errors.full_messages      # => ["Title can't be blank"]

# Test length validation (> 40 characters)
movie = Movie.new(title: 'A' * 50)
movie.valid?                    # => false
movie.errors[:title]            # => ["is too long (maximum is 40 characters)"]

# Test rating validation
movie = Movie.new(title: 'Test', rating: 'XXX')
movie.valid?                    # => false
movie.errors[:rating]           # => ["XXX is not a valid rating"]

# Valid movie
movie = Movie.new(title: 'Valid Movie', rating: 'PG', release_date: '01 Jan 2020')
movie.valid?                    # => true
movie.save!                     # Success!
```

#### Try It - Web Interface

1. Go to http://127.0.0.1:3000/movies/new
2. Try creating a movie with a title longer than 40 characters
3. Observe the validation error message

#### Model Lifecycle Callbacks

Validations run automatically during the model lifecycle:

```
movie.save (new record)     →  before_validation → validation → after_validation → before_save → before_create → INSERT → after_create → after_save
movie.save (existing)       →  before_validation → validation → after_validation → before_save → before_update → UPDATE → after_update → after_save
```

For example, we have defined 
```ruby
before_validation :normalize_title
```
and 
```ruby
  def normalize_title
    self.title = title.to_s.strip
  end
```
in `movie.rb`

---

### 1.2 Controller Filters

> *"Controller Filters provide a way to share functionality before each action"*

Filters use `before_action` to run code before controller actions.

**File: `app/controllers/movies_controller.rb`**

```ruby
class MoviesController < ApplicationController
  # This filter runs before show, edit, update, destroy actions
  before_action :set_movie, only: %i[ show edit update destroy ]

  private

  def set_movie
    @movie = Movie.find(params[:id])
  end
end
```

**File: `app/controllers/reviews_controller.rb`**

```ruby
class ReviewsController < ApplicationController
  before_action :set_movie          # Runs for ALL actions
  before_action :require_login      # Authentication filter
  before_action :set_review, only: [:show, :edit, :update, :destroy]

  private

  # Filter to load the parent movie (nested route)
  def set_movie
    @movie = Movie.find(params[:movie_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to movies_path, alert: 'Movie not found'
  end

  # Authentication filter - common pattern!
  def require_login
    # we exploit the fact that find_by_id(nil) returns nil
    @current_user ||= Moviegoer.find_by_id(session[:user_id])
    redirect_to login_path, alert: 'You must be logged in :(.' and return unless @current_user
  end
end
```

#### Key Points About Filters

| Feature | Description |
|---------|-------------|
| `before_action` | Runs before the controller action |
| `after_action` | Runs after the controller action |
| `only:` / `except:` | Limit which actions the filter applies to |
| Inheritance | Filters in `ApplicationController` apply to ALL controllers |
| Control Flow | Filters can `redirect_to` or `render` to halt execution |

#### Try It

1. Try accessing http://127.0.0.1:3000/movies/1/reviews/new without logging in
2. You'll be redirected to the login page with a flash message
3. Log in, then try again - now you can access the page

---

### 1.3 Partials

> *"render inside a view allows sharing code between views"*

Partials are reusable view fragments. By convention, their filenames start with `_`.

**File: `app/views/movies/_movie.html.erb`** - Movie partial

```erb
<div id="<%= dom_id movie %>">
  <p><strong>Title:</strong> <%= movie.title %></p>
  <p><strong>Rating:</strong> <%= movie.rating %></p>
  ...
</div>
```

**File: `app/views/movies/_form.html.erb`** - Form partial (used by new & edit)

```erb
<%= form_with(model: movie) do |form| %>
  ...
<% end %>
```

**File: `app/views/shared/_flash.html.erb`** - Shared flash partial

```erb
<%# Usage: <%= render 'shared/flash' %> %>
<% flash.each do |type, message| %>
  <div class="alert alert-<%= type %>">
    <%= message %>
  </div>
<% end %>
```

#### Partial Usage Examples

```erb
<%# Render a single movie %>
<%= render @movie %>

<%# Render a collection of movies %>
<%= render @movies %>

<%# Render with explicit partial name and local variables %>
<%= render partial: 'form', locals: { movie: @movie } %>

```

#### Best Practice

> **Tip:** Avoid using instance variables (`@movie`) directly in partials. Pass data as local variables instead. This makes partials more reusable.

---

## 2. Single Sign-On & Third-Party Authentication (ESaaS §5.2)

> *"OmniAuth gem helps a lot by providing uniform API to different strategies"*

### Authentication vs Authorization

| Concept | Definition | Example |
|---------|------------|---------|
| **Authentication** | Prove you are who you say | Login with username/password |
| **Authorization** | Prove you're allowed to do something | Check if user can edit a review |

### How OAuth Works (Simplified)

```
1. User clicks "Login with GitHub"
2. Redirect to GitHub login page
3. User authorizes the app
4. GitHub redirects back with access token
5. App uses token to get user info
6. App creates/finds local user, stores session
```

### Implementation Files

**File: `Gemfile`** - OmniAuth gems

```ruby
gem "omniauth"
gem "omniauth-github"
gem "omniauth-rails_csrf_protection"  # Required for Rails 7+
```

**File: `config/initializers/omniauth.rb`**

```ruby
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :github, ENV['GITHUB_CLIENT_ID'], ENV['GITHUB_CLIENT_SECRET'],
           scope: 'user:email'
  
  # Developer strategy for testing without real OAuth
  provider :developer if Rails.env.development?
end
```

**File: `app/models/moviegoer.rb`**

```ruby
class Moviegoer < ApplicationRecord
  # Find or create user from OmniAuth hash
  def self.from_omniauth(auth_hash)
    find_or_create_by(provider: auth_hash['provider'], uid: auth_hash['uid']) do |user|
      user.name = auth_hash['info']['name']
      user.email = auth_hash['info']['email']
    end
  end
end
```

**File: `app/controllers/sessions_controller.rb`**

```ruby
class SessionsController < ApplicationController
  # POST /auth/:provider/callback
  def create
    auth_hash = request.env['omniauth.auth']
    @moviegoer = Moviegoer.from_omniauth(auth_hash)
    
    # session[] remembers primary key of "currently authenticated user"
    session[:user_id] = @moviegoer.id
    
    flash[:notice] = "Welcome, #{@moviegoer.name}!"
    redirect_to movies_path
  end

  # DELETE /logout
  def destroy
    session.delete(:user_id)
    redirect_to movies_path
  end
end
```

**File: `app/controllers/application_controller.rb`**

```ruby
class ApplicationController < ActionController::Base
  helper_method :current_user, :logged_in?

  private

  def current_user
    @current_user ||= Moviegoer.find_by(id: session[:user_id]) if session[:user_id]
  end

  def logged_in?
    current_user.present?
  end
end
```

### Routes for Authentication

**File: `config/routes.rb`**

```ruby
# Session routes
get '/login', to: 'sessions#new', as: 'login'
delete '/logout', to: 'sessions#destroy', as: 'logout'

# OmniAuth callback routes
get '/auth/:provider/callback', to: 'sessions#create'
post '/auth/:provider/callback', to: 'sessions#create'
get '/auth/failure', to: 'sessions#failure'
```

#### Try It

1. Go to http://127.0.0.1:3000/login
2. Click "Developer Login (Testing Only)"
3. Enter any name and email
4. You're now logged in! See your name in the navbar.
5. Click "Logout" to end the session

#### Setting Up Real GitHub OAuth (Optional)

1. Go to https://github.com/settings/applications/new
2. Set **Authorization callback URL** to: `http://127.0.0.1:3000/auth/github/callback`
3. Copy the Client ID and Client Secret
4. Set environment variables:

```bash
export GITHUB_CLIENT_ID=your_client_id
export GITHUB_CLIENT_SECRET=your_client_secret
rails server
```

---

## 3. ActiveRecord Associations (ESaaS §5.3)

> *"After setting things up correctly, you don't have to worry (much) about keys and joins"*

### Basic Association Declaration

**File: `app/models/movie.rb`**

```ruby
class Movie < ApplicationRecord
  has_many :reviews, dependent: :destroy
end
```

**File: `app/models/review.rb`**

```ruby
class Review < ApplicationRecord
  belongs_to :movie      # "The foreign key belongs to movie"
  belongs_to :moviegoer
end
```

### The "belongs_to" Side Has the Foreign Key

```
reviews table:
+----+----------+----------+--------------+
| id | potatoes | movie_id | moviegoer_id |
+----+----------+----------+--------------+
|  1 |        5 |        1 |            1 |
|  2 |        4 |        1 |            2 |
+----+----------+----------+--------------+
         ↑           ↑
    Rating 1-5   Foreign Key
```

### Association Proxy Methods

```ruby
# Get all reviews for a movie (returns Enumerable)
@movie.reviews

# Get the movie for a review
@review.movie

# Build a new review (sets movie_id automatically)
@movie.reviews.build(potatoes: 5)

# Create and save a review
@movie.reviews.create!(potatoes: 5, moviegoer: current_user)

# Add existing review to movie (updates FK immediately!)
@movie.reviews << @new_review

# Query through association
@movie.reviews.where(potatoes: 5)
```

#### Try It - Rails Console

```ruby
# Find a movie
movie = Movie.find_by(title: 'Aladdin')

# See its reviews
movie.reviews
movie.reviews.count

# Get reviewer names
movie.reviews.map { |r| r.moviegoer.name }

# Go the other direction
review = Review.first
review.movie.title
review.moviegoer.name
```

---

## 4. Associations & Foreign Keys (ESaaS §5.4)

### Creating Associations with Migrations

**File: `db/migrate/20260130000002_create_reviews.rb`**

```ruby
class CreateReviews < ActiveRecord::Migration[7.1]
  def change
    create_table :reviews do |t|
      t.integer :potatoes, null: false

      # t.references creates the foreign key column
      # 'movie' becomes 'movie_id' in the database
      t.references :movie, null: false, foreign_key: true
      t.references :moviegoer, null: false, foreign_key: true

      t.timestamps
    end

    # Ensure a moviegoer can only review a movie once
    add_index :reviews, [:movie_id, :moviegoer_id], unique: true
  end
end
```

### Steps to Add a One-to-Many Association

1. Add `has_many` to owning model
2. Add `belongs_to` to owned model
3. Create migration with `t.references` for foreign key
4. Run `rails db:migrate`

#### Try It - View Schema

```bash
# See the generated schema
cat db/schema.rb
```

Look for the `reviews` table with `movie_id` and `moviegoer_id` columns.

---

## 5. Through-Associations (ESaaS §5.5)

> *"Scenario: Moviegoers rate Movies - a moviegoer can have many reviews, but a movie can also have many reviews"*

### Many-to-Many Through a Join Model

```
┌───────────────┐       ┌───────────────┐       ┌───────────────┐
│   moviegoers  │       │    reviews    │       │    movies     │
├───────────────┤       ├───────────────┤       ├───────────────┤
│ id            │←──┐   │ id            │   ┌──→│ id            │
│ name          │   └───│ moviegoer_id  │   │   │ title         │
│ email         │       │ movie_id      │───┘   │ rating        │
└───────────────┘       │ potatoes      │       └───────────────┘
                        └───────────────┘
```

### Model Declarations

**File: `app/models/moviegoer.rb`**

```ruby
class Moviegoer < ApplicationRecord
  has_many :reviews, dependent: :destroy
  has_many :movies, through: :reviews   # ← Through-association!
end
```

**File: `app/models/movie.rb`**

```ruby
class Movie < ApplicationRecord
  has_many :reviews, dependent: :destroy
  has_many :moviegoers, through: :reviews  # ← Through-association!
end
```

**File: `app/models/review.rb`**

```ruby
class Review < ApplicationRecord
  belongs_to :movie
  belongs_to :moviegoer
end
```

### What This Enables

```ruby
# Movies reviewed by a moviegoer
@moviegoer.movies

# moviegoers who reviewed a movie  
@movie.moviegoers

# My potato scores for R-rated movies
@moviegoer.reviews.select { |r| r.movie.rating == 'R' }
```

### Generated SQL

When you call `@user.movies`, Rails generates:

```sql
SELECT * FROM movies
  JOIN moviegoers ON 
    reviews.moviegoer_id = moviegoers.id
  JOIN movies ON 
    reviews.movie_id = movies.id
```

#### Try It - Rails Console

```ruby
# Find Alice (seeded user)
alice = Moviegoer.find_by(name: 'Alice')

# What movies has Alice reviewed?
alice.movies.pluck(:title)
# => ["Aladdin", "The Terminator", "The Incredibles"]

# Find Aladdin
aladdin = Movie.find_by(title: 'Aladdin')

# Who reviewed Aladdin?
aladdin.moviegoers.pluck(:name)
# => ["Alice", "Bob"]

# Alice's reviews of R-rated movies
alice.reviews.joins(:movie).where(movies: { rating: 'R' }).count
```

---

## 6. Referential Integrity

> *"What if we delete a movie with reviews?"*

### The Problem

If you delete a movie, its reviews would have `movie_id` pointing to a non-existent record.

### Solutions

**File: `app/models/movie.rb`**

```ruby
class Movie < ApplicationRecord
  # Option 1: Delete associated reviews (cascade delete)
  has_many :reviews, dependent: :destroy

  # Option 2: Set foreign key to NULL (orphan the reviews)
  # has_many :reviews, dependent: :nullify
  
  # Option 3: Prevent deletion if reviews exist
  # has_many :reviews, dependent: :restrict_with_error
end
```

#### Try It - Rails Console

```ruby
# Create a movie with a review
movie = Movie.create!(title: 'Test Movie', rating: 'PG', release_date: '2026-01-01')
alice = Moviegoer.first
review = movie.reviews.create!(moviegoer: alice, potatoes: 3)
review_id = review.id

# Delete the movie
movie.destroy

# Try to find the review - it's gone! (dependent: :destroy)
Review.find(review_id)
# => ActiveRecord::RecordNotFound
```

#### Try It - Web Interface

1. Go to a movie with reviews
2. Click "Destroy this movie"
3. Confirm the deletion
4. The movie AND all its reviews are deleted

---

### Quick Reference Commands

```bash
# Start server
rails server

# Open Rails console
rails console

# View all routes
rails routes

# View routes for reviews only
rails routes | grep review

# Run database migrations
rails db:migrate

# Reset database (drop, create, migrate, seed)
rails db:reset

# View schema
cat db/schema.rb
```

### Validations vs Filters Summary

| Aspect | Validations | Controller Filters |
|--------|-------------|-------------------|
| **Purpose** | Check model invariants | Check conditions before actions |
| **Location** | Model class | Controller class |
| **Pointcut** | Model lifecycle hooks | Before/after controller actions |
| **Can redirect?** | No | Yes |
| **Error info** | `model.errors` object | `flash[]`, `session[]` |

---

## Additional Resources

- [Rails Guides: Active Record Validations](https://guides.rubyonrails.org/active_record_validations.html)
- [Rails Guides: Active Record Associations](https://guides.rubyonrails.org/association_basics.html)
- [Rails Guides: Action Controller Overview](https://guides.rubyonrails.org/action_controller_overview.html#filters)
- [OmniAuth Wiki](https://github.com/omniauth/omniauth/wiki)
- [ESaaS Textbook Chapter 5](https://www.saasbook.info/)
