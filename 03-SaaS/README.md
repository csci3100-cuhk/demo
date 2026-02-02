# SaaS Introduction - Sinatra Demo Application

**CSCI3100: Software Engineering - Lecture 3: Introduction to Software as a Service (SaaS)**

This repository contains a simple Sinatra application demonstrating the core concepts of SaaS architecture covered in the lecture. Use this guide alongside the lecture PDF to explore each concept hands-on.

---

## Table of Contents

1. [Setup Instructions](#setup-instructions)
2. [The Web's Client-Server Architecture (ESaaS §3.1)](#1-the-webs-client-server-architecture-esaas-31)
3. [TCP/IP & HTTP: Routes (ESaaS §3.2)](#2-tcpip--http-routes-esaas-32)
4. [TCP/IP & HTTP: Cookies & Statelessness (ESaaS §3.2)](#3-tcpip--http-cookies--statelessness-esaas-32)
5. [Service-Oriented Architecture & Microservices (ESaaS §3.4)](#4-service-oriented-architecture--microservices-esaas-34)
6. [RESTful APIs (ESaaS §3.5)](#5-restful-apis-esaas-35)
7. [JSON (ESaaS §3.6)](#6-json-esaas-36)
8. [A Tour of Sinatra (ESaaS §3.7)](#7-a-tour-of-sinatra-esaas-37)
9. [RESTful Thinking (ESaaS §3.7)](#8-restful-thinking-esaas-37)
10. [Summary & Key Files](#summary--key-files)

---

## Setup Instructions

### Prerequisites
- Ruby 3.x
- Bundler

### Installation

```bash
# 1. Install dependencies
bundle install

# 2. Start the Sinatra server
bundle exec rackup

# Or with auto-reload on file changes (recommended for development)
bundle exec rerun -- rackup
```

Visit http://127.0.0.1:9292 to see the application.

### Quick Test

```bash
# Test the root route
curl http://127.0.0.1:9292/

# Test the hello route with a name parameter
curl http://127.0.0.1:9292/hello/World
```

---

## 1. The Web's Client-Server Architecture (ESaaS §3.1)

**Lecture Slides: 2-4**

### The Web at a High Level

```
┌──────────────┐         HTTP Request          ┌──────────────┐
│              │  ─────────────────────────>   │              │
│  Web Browser │                               │   Web Site   │
│   (Client)   │  <─────────────────────────   │   (Server)   │
│              │         HTTP Response         │              │
└──────────────┘                               └──────────────┘
        │
        │ DNS Query
        ▼
┌──────────────┐
│  DNS Server  │  (maps domain names to IP addresses)
└──────────────┘
```

### Client-Server Design Pattern

| Component | Responsibility |
|-----------|----------------|
| **Client** | Make queries on behalf of users |
| **Server** | Await & respond to queries, serve many clients |

### Key Characteristics

- **Request-Reply oriented**: Client sends request, server sends response
- **Asymmetric roles**: Clients and servers have different responsibilities
- **Frameworks exist for both sides**: 
  - Client-side: React, iOS, etc.
  - Server-side: Rails, Django, Sinatra, etc.

### Alternative: Peer-to-Peer

In P2P architecture, each participant is both a client AND a server.

---

## 2. TCP/IP & HTTP: Routes (ESaaS §3.2)

**Lecture Slides: 5-7**

### IP Addresses

- **IPv4 address**: Four octets (e.g., `128.32.244.172`)
- **localhost**: `127.0.0.1` - always refers to "this computer"

### TCP/IP

| Protocol | Purpose |
|----------|---------|
| **IP** | Best-effort packet delivery between addresses |
| **TCP** | Makes IP reliable (handles dropped packets, ordering, errors) |
| **TCP Ports** | Allow multiple apps on same computer (e.g., port 80 for HTTP) |

### Anatomy of a URL

```
GET http://srch.com:80/main/search?q=cloud&lang=en#top
    └─┬─┘ └───┬───┘└┬┘└─────┬────┘└───────┬──────┘└┬┘
   protocol  host  port   path        query    fragment
```

| Component | Description |
|-----------|-------------|
| **Protocol** | `http` or `https` (secure) |
| **Host** | Domain name or IP address |
| **Port** | Optional (default 80 for HTTP, 443 for HTTPS) |
| **Path** | Resource location on server |
| **Query** | Parameters (`key=value` pairs, separated by `&`) |
| **Fragment** | Client-side anchor (not sent to server) |

### HTTP Methods (Verbs)

| Method | Purpose |
|--------|---------|
| **GET** | Retrieve data |
| **POST** | Send data (create resource) |
| **PUT/PATCH** | Update resource |
| **DELETE** | Remove resource |
| **HEAD** | Get metadata only |

### HTTP Status Codes

| Range | Meaning |
|-------|---------|
| **2xx** | Success (e.g., 200 OK) |
| **3xx** | Redirect (e.g., 301 Moved Permanently) |
| **4xx** | Client error (e.g., 404 Not Found) |
| **5xx** | Server error (e.g., 500 Internal Server Error) |

### Route = HTTP Method + URI

A "route" is the combination of an HTTP method and a URI path:

```
GET  /movies           → List all movies
POST /movies           → Create a new movie
GET  /movies/42        → Show movie with ID 42
PUT  /movies/42        → Update movie with ID 42
DELETE /movies/42      → Delete movie with ID 42
```

#### Try It

```bash
# Make a GET request
curl -v http://127.0.0.1:9292/hello/World

# See the HTTP headers and response
```

---

## 3. TCP/IP & HTTP: Cookies & Statelessness (ESaaS §3.2)

**Lecture Slides: 8-9**

### HTTP is Stateless

> **Every HTTP request to the same server is independent of all prior requests!**

The server doesn't automatically "remember" previous requests from the same client.

### Cookies: Adding State to Stateless HTTP

```
First Request:
┌────────┐                    ┌────────┐
│ Client │ ─── GET /page ───> │ Server │
│        │ <── Set-Cookie ─── │        │
└────────┘    session=abc123  └────────┘

Subsequent Requests:
┌────────┐                    ┌────────┐
│ Client │ ─── GET /other ──> │ Server │
│        │    Cookie: abc123  │        │
│        │ <── Response ───── │        │
└────────┘                    └────────┘
```

### How Cookies Work

1. Server sends `Set-Cookie` header in response
2. Client stores the cookie value
3. Client includes cookie in all future requests to that server
4. Server uses cookie to identify/track the client

### Incognito Mode

"Incognito" or "Private" browsing mode destroys stored cookies when you close the browser.

#### Try It - Sessions in Our Demo

```bash
# Visit root (no session yet)
curl http://127.0.0.1:9292/

# Set a session value
curl -c cookies.txt http://127.0.0.1:9292/set/Alice

# Visit root again with the cookie
curl -b cookies.txt http://127.0.0.1:9292/
# Now shows "HELLO, Alice!"
```

---

## 4. Service-Oriented Architecture & Microservices (ESaaS §3.4)

**Lecture Slides: 10-15**

### Evolution: Web 1.0 to Web 2.0

| Web 1.0 | Web 2.0 |
|---------|---------|
| Static HTML pages | Dynamic content |
| Full page reloads | Partial page updates (AJAX) |
| Server renders everything | Client-side rendering |

### AJAX (Asynchronous JavaScript and XML)

- Browser uses `XMLHttpRequest` (or `fetch`) to make requests in the background
- Page can update without full reload
- Despite the name, usually uses JSON (not XML)

### Microservices

> **Microservice**: Independently-deployable component that supports message-based communication

| Pros | Cons |
|------|------|
| Small, focused components | Performance overhead |
| "You build it, you run it" | Managing partial failures |
| Compose into larger services | More interfaces to track |
| Quick enhancements | DevOps complexity |

---

## 5. RESTful APIs (ESaaS §3.5)

**Lecture Slides: 16-19**

### REST: Representational State Transfer

REST is a canonical way of mapping URIs and HTTP methods to operations on resources (Roy Fielding, 2000).

### Core Principle

> **Everything the server manages is a resource.**

### CRUD Operations

| Operation | HTTP Method | Example |
|-----------|-------------|---------|
| **C**reate | POST | `POST /movies` |
| **R**ead | GET | `GET /movies/42` |
| **U**pdate | PUT/PATCH | `PUT /movies/42` |
| **D**elete | DELETE | `DELETE /movies/42` |
| Index (list) | GET | `GET /movies` |

### Procedure Call vs. API Call

| Aspect | Procedure Call | RESTful API |
|--------|----------------|-------------|
| Identify callee | Function name | Endpoint (base URI + path) |
| Operation | Function name | HTTP method + path |
| Arguments | Function params | Path params, query params, JSON body |
| Return value | Return statement | HTTP response body |
| Errors | Exceptions | HTTP status codes + error message |

### Resource-First vs Action-First Thinking

**Action-First** (NOT RESTful):
```
/searchProducts?q=laptop
/addToCart?product=123
/checkout
```

**Resource-First** (RESTful):
```
GET    /products?q=laptop     # Index/search products
POST   /carts                 # Create a cart
PUT    /carts/1               # Update cart with product
POST   /orders                # Create an order
```

---

## 6. JSON (ESaaS §3.6)

**Lecture Slides: 17-18, 20-23**

### JavaScript Object Notation

JSON is the standard data format for web APIs.

### Primitive Types

| Type | Example |
|------|---------|
| String | `"hello"` |
| Number | `42`, `3.14` |
| Boolean | `true`, `false` |
| Null | `null` |
| Array | `[1, 2, 3]` |
| Object | `{"key": "value"}` |

### Example: Movie Data

```json
{
  "movie": {
    "id": 62,
    "title": "2001: A Space Odyssey",
    "release_date": "1968-04-02",
    "rating": "G",
    "genres": ["Science Fiction", "Drama"]
  }
}
```

### JSON vs XML

```json
{
  "person": {
    "name": "John Doe",
    "age": 30,
    "city": "Hong Kong"
  }
}
```

```xml
<person>
  <name>John Doe</name>
  <age>30</age>
  <city>Hong Kong</city>
</person>
```

JSON is more compact and easier to parse in JavaScript.

### Example: TheMovieDB API

```bash
# Get movie details
curl --request GET \
  --url 'https://api.themoviedb.org/3/movie/62' \
  --header 'Authorization: Bearer YOUR_API_KEY' \
  --header 'accept: application/json'

# Post a rating
curl --request POST \
  --url 'https://api.themoviedb.org/3/movie/62/rating' \
  --header 'Authorization: Bearer YOUR_API_KEY' \
  --header 'Content-Type: application/json' \
  --data '{"value": 8.5}'
```

### Reading API Documentation

> **Reading API docs is a life skill!**

- Check authentication requirements
- Use `curl` to test endpoints
- Use `jq` to format/inspect JSON output

```bash
# Pretty-print JSON with jq
curl -s http://api.example.com/data | jq '.'
```

---

## 7. A Tour of Sinatra (ESaaS §3.7)

**Lecture Slides: 27-28**

### What is Sinatra?

Sinatra is a lightweight Ruby web framework—much simpler than Rails, great for learning SaaS concepts.

### Project Structure

```
03-SaaS/
├── app.rb          # Application code (routes & logic)
├── config.ru       # Rack configuration (entry point)
├── Gemfile         # Ruby dependencies
└── views/
    ├── hello.erb   # View template
    └── layout.erb  # Layout template (wraps all views)
```

### The Application File

**File: `app.rb`**

```ruby
require 'sinatra'

class DemoApp < Sinatra::Base

    enable :sessions  # Enable cookie-based sessions

    # Route: GET /
    get '/' do
        @user_name = session[:value]  # Read from session
        erb :hello                     # Render views/hello.erb
    end

    # Route: GET /set/:value
    # :value is a path parameter
    get '/set/:value' do
      session[:value] = params[:value]  # Store in session
      redirect '/'                       # Redirect to root
    end

    # Route: GET /hello/:name
    get '/hello/:name' do
        @user_name = params[:name]  # Get from URL
        erb :hello
    end
end
```

### Key Sinatra Concepts

| Concept | Description |
|---------|-------------|
| **Routes** | `get '/path'`, `post '/path'`, etc. |
| **Path Parameters** | `:like_this` in path, accessed via `params[:like_this]` |
| **Views** | ERB templates in `views/` directory |
| **Instance Variables** | `@variables` set in routes are visible in views |
| **Sessions** | `session[]` hash persists data using cookies |
| **Redirect** | `redirect '/path'` sends HTTP redirect |

### The Rack Configuration

**File: `config.ru`**

```ruby
require './app'

run DemoApp
```

This tells Rack (the web server interface) to run our Sinatra app.

### View Templates

**File: `views/hello.erb`**

```erb
<h1>CSCI3100</h1>

<p>HELLO, <%= @user_name %> ! </p>
```

ERB (Embedded Ruby) allows Ruby code in HTML:
- `<%= expression %>` - Output the result
- `<% code %>` - Execute code (no output)

### Layout Template

**File: `views/layout.erb`**

```erb
<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8">
    <title>Wordguesser</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.8/dist/css/bootstrap.min.css" rel="stylesheet">
  </head>
  <body>
    <div class="container">
      <%= yield %>  <!-- View content goes here -->
    </div>
  </body>
</html>
```

The `<%= yield %>` is replaced with the content of the specific view being rendered.

#### Try It

1. Start the server: `bundle exec rackup`
2. Visit http://127.0.0.1:9292/ - See "HELLO, !"
3. Visit http://127.0.0.1:9292/hello/Alice - See "HELLO, Alice!"
4. Visit http://127.0.0.1:9292/set/Bob - Sets session, redirects to root
5. Visit http://127.0.0.1:9292/ - Now see "HELLO, Bob!" (session remembered!)

---

## 8. RESTful Thinking (ESaaS §3.7)

**Lecture Slides: 29-30**

### Designing a SaaS Application

When "webifying" an app, think about:

1. **What resources are exposed?**
   - These become your models
   - Example: Movies, Users, Reviews

2. **What state must be maintained?**
   - Store in cookie (session)?
   - Store in database, reference in cookie?

3. **How to map to routes?**
   - Resource access → GET routes
   - State changes → POST/PUT/DELETE routes

### Example: Tic-Tac-Toe Game

| Resource | Operations |
|----------|------------|
| Game | Create, Show, Update |

| Route | Purpose |
|-------|---------|
| `POST /games` | Create new game |
| `GET /games/:id` | Show game board |
| `PUT /games/:id` | Make a move |

### Session vs Database Storage

| Storage | Use When |
|---------|----------|
| **Session (cookie)** | Small, temporary data for one user |
| **Database** | Persistent data, shared across users |

---

## Summary & Key Files

### Sinatra Highlights

| Feature | Description |
|---------|-------------|
| Route declaration | `get '/path' do ... end` |
| Path parameters | `:param` parsed into `params[]` |
| Views | ERB templates in `views/` |
| Instance variables | `@var` in controller visible in view |
| View rendering | `erb :viewname` |
| Layout | `layout.erb` frames each view |
| Sessions | `session[]` uses cookies to persist |
| Redirect | `redirect '/path'` |

### File Reference

| File | Purpose |
|------|---------|
| `app.rb` | Application routes and logic |
| `config.ru` | Rack configuration (entry point) |
| `Gemfile` | Ruby dependencies |
| `views/hello.erb` | View template |
| `views/layout.erb` | Layout wrapper for all views |

### Comparing Sinatra and Rails

| Aspect | Sinatra | Rails |
|--------|---------|-------|
| Complexity | Minimal | Full-featured |
| Structure | Single file possible | MVC directories |
| Routes | Inline with code | Separate `routes.rb` |
| ORM | None built-in | ActiveRecord |
| Best for | Learning, small apps, APIs | Full web applications |

### Quick Reference Commands

```bash
# Install dependencies
bundle install

# Start server (default port 9292)
bundle exec rackup

# Start with auto-reload
bundle exec rerun -- rackup

# Start on different port
bundle exec rackup -p 3000

# Test with curl
curl http://127.0.0.1:9292/hello/World
```

---

## Exercises for Students

### Exercise 1: Add a New Route
Add a route `GET /goodbye/:name` that displays "Goodbye, {name}!". Create a new view `goodbye.erb`.

### Exercise 2: Form Submission
Add a form that lets users type their name and submit it. The form should:
1. Display at `GET /form`
2. Submit to `POST /greet`
3. Store the name in session and redirect to root

### Exercise 3: Counter
Implement a page visit counter using sessions:
1. `GET /counter` - Display current count
2. `POST /counter/increment` - Increment and redirect
3. `POST /counter/reset` - Reset to 0 and redirect

### Exercise 4: JSON API
Add a route `GET /api/greeting/:name` that returns JSON:
```json
{"message": "Hello, Alice!", "timestamp": "2026-01-19T10:30:00Z"}
```

Hint: Use `content_type :json` and `{...}.to_json`

---

## Additional Resources

- [Sinatra Documentation](http://sinatrarb.com/documentation.html)
- [Sinatra README](http://sinatrarb.com/intro.html)
- [ERB Tutorial](https://www.stuartellis.name/articles/erb/)
- [HTTP Status Codes](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status)
- [REST API Tutorial](https://restfulapi.net/)
- [JSON.org](https://www.json.org/)
- [ESaaS Textbook Chapter 3](https://www.saasbook.info/)
