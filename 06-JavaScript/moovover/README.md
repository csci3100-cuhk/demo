# MoovOver - JavaScript & Accessibility Demo Application

**CSCI3100: Software Engineering - Lecture 6: Enhancing SaaS with JavaScript**

This repository demonstrates all the JavaScript concepts covered in Lecture 6 (ESaaS Chapter 6). The codebase builds on the Advanced Rails app from Lecture 5, adding client-side JavaScript, jQuery, AJAX, and accessibility (a11y) enhancements. Use this guide alongside the lecture PDF to explore each concept hands-on.

---

## Table of Contents

1. [Setup Instructions](#setup-instructions)
2. [JavaScript: The Big Picture (ESaaS §6.1-6.2)](#1-javascript-the-big-picture-esaas-612)
   - [Progressive Enhancement](#11-progressive-enhancement)
   - [The Module Pattern](#12-the-module-pattern--variable-scope)
3. [Client-Side JavaScript for Ruby Programmers (ESaaS §6.2)](#2-client-side-javascript-for-ruby-programmers-esaas-62)
4. [Functions (ESaaS §6.3)](#3-functions-esaas-63)
5. [The DOM & jQuery (ESaaS §6.4)](#4-the-dom--jquery-esaas-64)
   - [Three Ways to Call $()](#41-three-ways-to-call-)
   - [Demo: Select All Movie Titles](#42-demo-select-all-movie-titles)
6. [DOM and Accessibility (ESaaS §6.5)](#5-dom-and-accessibility-esaas-65)
   - [Semantic HTML](#51-semantic-html)
   - [Form Labels](#52-form-inputs-need-labels)
   - [ARIA Attributes](#53-aria-attributes)
   - [Keyboard Navigation](#54-keyboard-navigation)
7. [Events & Callbacks (ESaaS §6.6)](#6-events--callbacks-esaas-66)
8. [AJAX (ESaaS §6.7)](#7-ajax-asynchronous-javascript-and-xml-esaas-67)
   - [The AJAX Cycle](#71-the-ajax-cycle)
   - [AJAX with Rails](#72-rails-cookery-ajax-with-rails)
   - [Demo: Movie Quick View Popup](#73-demo-movie-quick-view-popup)
9. [Intro to Jasmine: TDD for JavaScript (ESaaS §6.8)](#8-intro-to-jasmine-tdd-for-javascript-esaas-68)
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

## 1. JavaScript: The Big Picture (ESaaS §6.1-6.2)

**Lecture Slides: 3-10**

JavaScript is embedded in the browser, giving it privileged access to:
1. Be triggered by **user-initiated events** (mouse click, keypress, ...)
2. Make **HTTP requests** to the server **without page reload** (AJAX)
3. Be triggered by **network events** (server responds to AJAX request)
4. **Inspect & modify** the current document (DOM manipulation)

### 1.1 Progressive Enhancement

**Lecture Slides: 10**

> *"Browsers with JS disabled should get a usable experience"*

Our app follows progressive enhancement: the app works WITHOUT JavaScript, but JS **enhances** the experience when available.

**File: `app/views/movies/index.html.erb`**

```erb
<%# The "Quick View" link works two ways:
    1. WITHOUT JS: navigates to the show page (standard Rails link)
    2. WITH JS: opens an AJAX popup (enhanced experience!) %>
<%= link_to "Quick View", movie_path(movie),
      class: "btn btn-sm btn-outline-primary movie-popup-link",
      data: { movie_id: movie.id } %>
```

#### Try It

1. Visit http://127.0.0.1:3000/movies
2. Click "Quick View" on any movie - an AJAX popup appears (JS enhanced)
3. Now disable JavaScript in your browser (normally, Settings > Content > JavaScript)
4. Click "Quick View" again - it navigates to the full show page (still works!)

### 1.2 The Module Pattern & Variable Scope

**Lecture Slides: 16-18**

> *"Best practice: create modules — a global variable that is an object whose properties are your functions & attributes"*

In JavaScript, `var` without `let`/`const` in the outermost scope creates globals. We avoid this by using the **module pattern**.

**File: `app/javascript/movie_popup.js`**

```javascript
// The module pattern: ONE global variable whose properties are functions
let MoviePopup = {
  setup: function() { ... },
  getMovieInfo: function() { ... },
  showPopup: function() { ... },
  hidePopup: function() { ... },
  toggleSelectAll: function() { ... }
};
```

Compare with the alternative syntax (same effect):

```javascript
let MoviePopup = {};
MoviePopup.setup = function() { ... };
MoviePopup.getMovieInfo = function() { ... };
```

<!-- #### Key Scoping Rules

| Keyword | Scope | Use Case |
|---------|-------|----------|
| `var` | Function scope | Avoid in modern JS |
| `let` | Block scope | Mutable variables |
| `const` | Block scope | Immutable bindings (objects can still mutate!) |
| (none) | Global (window) | Almost never what you want! | -->

---

## 2. Client-Side JavaScript for Ruby Programmers (ESaaS §6.2)

**Lecture Slides: 13-19**

JavaScript and Ruby share many features:

| Feature | Ruby | JavaScript |
|---------|------|------------|
| Typing | Dynamic | Dynamic |
| String interpolation | `"Hello #{name}"` | `` `Hello ${name}` `` |
| First-class functions | `lambda {\|x\| x*2 }` | `(x) => x*2` |
| Regex | `/pattern/` | `/pattern/` |
| Collections | `[1,2,3].map { \|x\| x*x }` | `[1,2,3].map(x => x*x)` |
| Inheritance | Class-based | Prototype-based (class syntax is sugar) |

### How JS is Loaded in Rails

**File: `app/views/layouts/application.html.erb`**

```erb
<%# Rails 7 uses importmap to load JavaScript (ESaaS §6.1) %>
<%= javascript_importmap_tags %>

<%# jQuery loaded via CDN for DOM manipulation demos (ESaaS §6.4) %>
<script src="https://code.jquery.com/jquery-3.7.1.min.js" ...></script>
```

**File: `config/importmap.rb`**

```ruby
pin "application"
pin "movie_popup"  # Our custom JS loaded as ES module
```

**File: `app/javascript/application.js`**

```javascript
import "@hotwired/turbo-rails"
import "controllers"
import "movie_popup"  // Our AJAX + jQuery demo code
```

---

## 3. Functions (ESaaS §6.3)

**Lecture Slides: 20-29**

> *"Functions are first-class objects & closures"*

JavaScript functions are closures — they capture their enclosing scope.

### Function Styles in Our Code

**File: `app/javascript/movie_popup.js`**

```javascript
// 1. Named function expression (property of an object)
setup: function() { ... }

// 2. Arrow function - concise syntax for callbacks
// (response) => { ... } is shorthand for function(response) { ... }
success: (response) => {
  MoviePopup.showMovieData(response);
}

// 3. Short arrow function (implicit return, no braces)
// [1, 2, 3].map(x => x * x) → [1, 4, 9]
```

### Class Syntax (for reference)

```javascript
class Movie {
  constructor(title, year, rating) {
    this.title = title;
    this.year = year;
    this.rating = rating;
  }
  ok_for_kids() {
    return /^G|PG/.test(this.rating);
  }
  full_title = () => `${this.title} (${this.year})`;
}
```

#### Try It - Browser Console

Open the browser console (F12 or Cmd+Option+J) on any page:

```javascript
// Closures
let make_times = function(mul) {
  return function(arg) { return arg * mul; }
}
let times2 = make_times(2);
let times3 = make_times(3);
times2(5)   // → 10
times3(5)   // → 15

// Arrow functions
[1, 2, 3].map(x => x * x)   // → [1, 4, 9]

// Our module is accessible globally
MoviePopup
```

---

## 4. The DOM & jQuery (ESaaS §6.4)

**Lecture Slides: 30-38**

> *"DOM is a language-independent, hierarchical representation of an HTML document"*

The DOM (Document Object Model) is a tree of objects that the browser creates from HTML. jQuery provides a powerful, cross-browser API to manipulate the DOM.

### 4.1 Three Ways to Call $()

| Way | Example | Purpose |
|-----|---------|---------|
| **#1: Select** | `$('#movies')`, `$('.heading')`, `$('table')` | Find DOM elements using CSS selectors |
| **#2: Create** | `$('<div class="main"></div>')` | Create new DOM elements |
| **#3: Ready** | `$(function() { ... })` | Run code when DOM is loaded |

All three are demonstrated in our code:

**File: `app/javascript/movie_popup.js`**

```javascript
// Way #1 - Select DOM elements
MoviePopup.$popup = $('#movie-popup');
MoviePopup.$closeBtn = $('#movie-popup-close');

// Way #1 - Select with pseudo-class
let count = $('.movie-checkbox:checked').length;

// Way #3 - Run setup when DOM is ready
$(MoviePopup.setup);
```

### jQuery DOM Inspection Methods

| Method | Purpose | Example |
|--------|---------|---------|
| `.text()` / `.html()` | Get/set text or HTML content | `$('#title').text()` |
| `.is(':checked')` | Inspect element state | `$(this).is(':checked')` |
| `.attr('name')` | Get/set HTML attributes | `$link.attr('href')` |
| `.data('key')` | Read data-* attributes | `$link.data('movie-id')` |
| `.show()` / `.hide()` | Show/hide elements | `$('#popup').show()` |
| `.addClass()` / `.removeClass()` | Modify CSS classes | `$el.addClass('active')` |
| `.prop('checked', true)` | Set DOM properties | Check a checkbox |

### 4.2 Demo: Select All Movie Titles

**Lecture Slides: 39**

The index page includes a "Select All" checkbox that demonstrates jQuery DOM manipulation.

#### Try It

1. Go to http://127.0.0.1:3000/movies
2. Click the "Select All" checkbox - all movie checkboxes are checked
3. Uncheck it - all are unchecked
4. Check individual movies - the count badge updates

#### Try It - Browser Console

```javascript
// Select all movie title elements
$('.movie-row strong').each(function() {
  console.log($(this).text());
});

// Count checked movies
$('.movie-checkbox:checked').length

// Check all checkboxes programmatically
$('.movie-checkbox').prop('checked', true);

// Get the movie popup element
$('#movie-popup').is(':visible')  // → false (hidden initially)
```

---

## 5. DOM and Accessibility (ESaaS §6.5)

**Lecture Slides: 40-58**

> *"Accessibility is ensuring our apps work for everyone"*

### 5.1 Semantic HTML

**Lecture Slides: 48-49**

> *"Why not just shove everything in a `<div>`? HTML elements convey a lot of description."*

Screen readers, search engines, and bots use HTML tags to understand content meaning.

**File: `app/views/layouts/application.html.erb`**

```erb
<%# Semantic elements used in our layout: %>
<nav aria-label="Main navigation">    <%# Not <div class="nav"> %>
<main id="main-content" role="main">  <%# Not <div class="content"> %>
<footer role="contentinfo">           <%# Not <div class="footer"> %>
```

**File: `app/views/movies/_movie.html.erb`**

```erb
<%# <article> for self-contained content (vs. generic <div>) %>
<article id="<%= dom_id movie %>" aria-label="Movie: <%= movie.title %>">
  ...
  <%# <time> element for machine-readable dates %>
  <time datetime="<%= movie.release_date.to_s %>"><%= movie.release_date %></time>
  ...
</article>
```

**File: `app/views/movies/show.html.erb`**

```erb
<%# <section> with aria-labelledby groups related content %>
<section aria-labelledby="reviews-heading">
  <h3 id="reviews-heading">Reviews</h3>
  ...
</section>

<%# <nav> for action links (not a generic <div>) %>
<nav aria-label="Movie actions">
  ...
</nav>
```

### 5.2 Form Inputs Need Labels!

**Lecture Slides: 51**

> *"When you use a form input, you must provide a label"*

Every form input needs a `<label>` with a `for` attribute matching the input's `id`. Rails helpers do this automatically.

**File: `app/views/movies/_form.html.erb`**

```erb
<%# Rails generates matching for/id attributes: %>
<%= form.label :title, class: "form-label" %>
<%# → <label for="movie_title">Title</label> %>

<%= form.text_field :title, class: "form-control" %>
<%# → <input type="text" id="movie_title" name="movie[title]"> %>

<%# aria-describedby links to help text for screen readers %>
<%= form.text_field :title, aria: { describedby: "title-help" } %>
<div id="title-help" class="form-text">Required. Maximum 10 characters.</div>
```

**File: `app/views/movies/index.html.erb`**

```erb
<%# Each checkbox has an aria-label describing its purpose %>
<input type="checkbox" id="select-all-movies"
       aria-label="Select all movies">
<label for="select-all-movies">Select All</label>

<%# Individual movie checkboxes also have labels %>
<input type="checkbox" class="movie-checkbox"
       id="movie-check-<%= movie.id %>"
       aria-label="Select <%= movie.title %>">
```

### 5.3 ARIA Attributes

**Lecture Slides: 50, 52**

ARIA (Accessible Rich Internet Applications) attributes describe element behavior for assistive technology.

```erb
<%# role="dialog" tells screen readers this is a dialog %>
<div id="movie-popup" role="dialog" aria-label="Movie details" aria-hidden="true">

<%# role="status" for non-critical updates; role="alert" for important ones %>
<div class="alert alert-info" role="status" aria-live="polite">
<div class="alert alert-danger" role="alert" aria-live="assertive">

<%# aria-live="polite" announces changes without interrupting %>
<span id="selected-count" aria-live="polite">
```

**File: `app/javascript/movie_popup.js`**

```javascript
// §6.5 - Use JS to keep ARIA attributes in sync with visual state
showPopup: function() {
  MoviePopup.$popup.show();
  MoviePopup.$popup.attr('aria-hidden', 'false');  // Update ARIA
  MoviePopup.$closeBtn.focus();                     // Move focus for keyboard users
},

hidePopup: function() {
  MoviePopup.$popup.hide();
  MoviePopup.$popup.attr('aria-hidden', 'true');    // Update ARIA
}
```

### 5.4 Keyboard Navigation

**Lecture Slides: 44**

> *"Tab, space, return keys allow a user to navigate between interactive elements"*

Our implementation includes:

| Feature | Implementation |
|---------|---------------|
| Skip navigation | `<a href="#main-content" class="visually-hidden-focusable">Skip to main content</a>` |
| Escape to close | `$(document).on('keydown', ...)` checks for Escape key |
| Focus management | Popup moves focus to close button; closing returns focus |
| Focus indicators | CSS `:focus` outlines on all interactive elements |

#### Try It

1. Go to http://127.0.0.1:3000/movies
2. Press **Tab** — focus moves through interactive elements
3. First Tab press shows the "Skip to main content" link
4. Click "Quick View" to open the popup
5. Press **Escape** — the popup closes
6. Tab through the form at http://127.0.0.1:3000/movies/new — note labels are announced

---

## 6. Events & Callbacks (ESaaS §6.6)

**Lecture Slides: 59-63**

> *"Events are occurrences that affect the user interface"*

### Event Handling Pattern

1. Identify elements you want to interact with (make them selectable with `$()`)
2. Identify elements on which interactions trigger behavior
3. Write handler functions
4. In a **setup function**, bind the handlers

**File: `app/javascript/movie_popup.js`**

```javascript
// Step 4: Setup function binds handlers to elements
setup: function() {
  // Bind close button click event
  MoviePopup.$closeBtn.on('click', MoviePopup.hidePopup);

  // Bind Escape key (keyboard accessibility)
  $(document).on('keydown', function(event) {
    if (event.key === 'Escape' && MoviePopup.$popup.is(':visible')) {
      MoviePopup.hidePopup();
    }
  });

  // Event Delegation: bind on parent, filter by selector
  // This handles clicks on .movie-popup-link elements even if
  // added to DOM AFTER setup() runs
  $(document).on('click', '.movie-popup-link', MoviePopup.getMovieInfo);

  // Bind "Select All" checkbox
  $('#select-all-movies').on('change', MoviePopup.toggleSelectAll);
}
```

### Events on Links & Buttons

When a link already has a default action (navigation), the handler runs first:
- If handler calls `event.preventDefault()` → default action is suppressed
- Otherwise, default action follows after handler

```javascript
getMovieInfo: function(event) {
  // Prevent default link navigation — we'll handle it with AJAX
  event.preventDefault();
  // ... AJAX call instead of page navigation ...
}
```

### The Select All Handler

```javascript
toggleSelectAll: function() {
  // $(this) refers to the element that triggered the event
  let isChecked = $(this).is(':checked');
  // .prop() sets DOM property on all matching elements
  $('.movie-checkbox').prop('checked', isChecked);
  MoviePopup.updateSelectedCount();
}
```

#### Try It - Browser Console

```javascript
// Trigger events programmatically
$('#select-all-movies').trigger('click');

// Bind a custom event handler
$('.movie-row').on('mouseenter', function() {
  $(this).css('background-color', '#e8f4fd');
}).on('mouseleave', function() {
  $(this).css('background-color', '');
});
```

---

## 7. AJAX: Asynchronous JavaScript And XML (ESaaS §6.7)

**Lecture Slides: 64-70**

> *"XmlHttpRequest contacts server asynchronously (in background) and without redrawing page"*

### 7.1 The AJAX Cycle

```
1. User clicks "Quick View" link           (Event - §6.6)
2. JS handler intercepts click              (preventDefault)
3. JS makes background HTTP request         ($.ajax or fetch)
4. Server receives request, processes it    (Controller action)
5. Server returns JSON/HTML response        (respond_to format.json)
6. JS callback receives data                (success function)
7. JS updates DOM with new data             (jQuery .html())
```

### 7.2 Rails Cookery: AJAX with Rails

**Server Side - File: `app/controllers/movies_controller.rb`**

```ruby
# GET /movies/1 or /movies/1.json
# The SAME action handles both regular and AJAX requests!
def show
  # respond_to determines what to render based on format:
  #   - Regular request → show.html.erb
  #   - AJAX JSON request → show.json.jbuilder
end
```

The JSON response is built by the jbuilder template:

**File: `app/views/movies/_movie.json.jbuilder`**

```ruby
# This renders when format.json is requested
json.extract! movie, :id, :title, :rating, :description, :release_date
json.review_count movie.reviews.count
```

**Client Side - File: `app/javascript/movie_popup.js`**

```javascript
// The jQuery AJAX call
$.ajax({
  type: 'GET',
  url: '/movies/' + movieId + '.json',  // Request JSON format
  timeout: 5000,
  success: (response) => {
    // Callback: unpack JSON and update DOM
    MoviePopup.showMovieData(response);
  },
  error: (xhr, status, error) => {
    // Handle errors gracefully
    MoviePopup.$popupBody.html('<div class="alert alert-danger">Error</div>');
  }
});
```

### Alternative: fetch() API

Modern JavaScript provides `fetch()` as an alternative to `$.ajax()`:

```javascript
// fetch() returns a Promise with .then() chaining
fetch('/movies/' + movieId + '.json')
  .then((response) => {
    if (response.ok) { return response.json(); }
    throw new Error('Something went wrong');
  })
  .then((data) => {
    MoviePopup.showMovieData(data);
  })
  .catch((error) => { console.log(error); });
```

### 7.3 Demo: Movie Quick View Popup

The "Quick View" button on the movies index page demonstrates the full AJAX cycle.

#### Try It

1. Go to http://127.0.0.1:3000/movies
2. Click "Quick View" on any movie
3. A popup appears showing movie details loaded via AJAX
4. Click the X button or press Escape to close
5. Open the browser's **Network** tab (F12 → Network)
6. Click "Quick View" again and observe the XHR request:
   - URL: `/movies/1.json`
   - Method: GET
   - Response: JSON data

#### Try It - Browser Console

```javascript
// Make an AJAX request manually
$.ajax({
  type: 'GET',
  url: '/movies/1.json',
  success: function(data) {
    console.log('Movie:', data.title);
    console.log('Rating:', data.rating);
    console.log('Reviews:', data.review_count);
  }
});

// Same thing with fetch()
fetch('/movies/1.json')
  .then(r => r.json())
  .then(data => console.log(data));
```

---

## Summary & Key Files

### Concept-to-File Mapping

| Concept | Lecture Section | File(s) |
|---------|-----------------|---------|
| Progressive Enhancement | §6.1 | `app/views/movies/index.html.erb` |
| Module Pattern / Scope | §6.2 | `app/javascript/movie_popup.js` |
| JS Loading in Rails | §6.1 | `app/views/layouts/application.html.erb`, `config/importmap.rb` |
| Functions & Closures | §6.3 | `app/javascript/movie_popup.js` (arrow functions, callbacks) |
| jQuery DOM Manipulation | §6.4 | `app/javascript/movie_popup.js` (selectors, `.html()`, `.show()`) |
| Select All Demo | §6.4, §6.6 | `app/views/movies/index.html.erb`, `app/javascript/movie_popup.js` |
| Semantic HTML | §6.5 | `app/views/layouts/application.html.erb`, `app/views/movies/_movie.html.erb` |
| Form Labels / a11y | §6.5 | `app/views/movies/_form.html.erb` |
| ARIA Attributes | §6.5 | All view files, `app/javascript/movie_popup.js` |
| Keyboard Navigation | §6.5 | `app/assets/stylesheets/application.css`, `app/javascript/movie_popup.js` |
| Events & Callbacks | §6.6 | `app/javascript/movie_popup.js` (`.on()`, event delegation) |
| AJAX with jQuery | §6.7 | `app/javascript/movie_popup.js` (`$.ajax()`) |
| AJAX with fetch() | §6.7 | `app/javascript/movie_popup.js` (`getMovieInfoWithFetch`) |
| Rails AJAX Controller | §6.7 | `app/controllers/movies_controller.rb` (`respond_to`) |
| JSON Response | §6.7 | `app/views/movies/_movie.json.jbuilder` |
| Popup CSS | §6.4, §6.7 | `app/assets/stylesheets/application.css` |

### Architecture: How the Pieces Fit Together

```
Browser (Client)                         Rails Server
┌────────────────────────┐               ┌──────────────────────┐
│ HTML Page              │               │ MoviesController     │
│ ┌──────────────────┐   │   HTTP GET    │ ┌──────────────────┐ │
│ │ jQuery ($)       │───┼──────────────>│ │ def show         │ │
│ │ movie_popup.js   │   │  /movies/1    │ │   @movie = ...   │ │
│ │ MoviePopup module│   │   .json       │ │   respond_to ... │ │
│ └──────────────────┘   │               │ └──────────────────┘ │
│         │              │   JSON        │         │            │
│         ▼              │<──────────────│         ▼            │
│ ┌──────────────────┐   │  {title:...}  │ _movie.json.jbuilder │
│ │ DOM Manipulation │   │               │                      │
│ │ Show popup       │   │               │                      │
│ │ Update content   │   │               │                      │
│ └──────────────────┘   │               │                      │
└────────────────────────┘               └──────────────────────┘
```

### Quick Reference Commands

```bash
# Start server
rails server

# Open Rails console
rails console

# View all routes (including JSON routes)
rails routes

# Reset database
rails db:reset

# Test JSON endpoint directly
curl http://127.0.0.1:3000/movies/1.json
```

### JavaScript Quick Reference

```javascript
// jQuery Selectors (§6.4)
$('#id')                  // By ID
$('.class')               // By class
$('tag')                  // By tag name
$('#movies tr')           // Descendant selector
$('.movie-checkbox:checked') // With pseudo-class

// jQuery DOM Methods (§6.4)
$el.text()                // Get text content
$el.html('<p>new</p>')    // Set HTML content
$el.show() / $el.hide()  // Show/hide
$el.attr('name', 'val')  // Set attribute
$el.prop('checked', true) // Set property

// Events (§6.6)
$el.on('click', handler)  // Bind event
$(document).on('click', '.selector', handler) // Event delegation

// AJAX (§6.7)
$.ajax({ type: 'GET', url: '/path.json', success: fn, error: fn })
fetch('/path.json').then(r => r.json()).then(data => ...)
```

---

## Exercises for Students

### Exercise 1: Add Client-Side Form Validation
Add JavaScript validation to the movie form that shows an error message (without submitting) if the title is empty. Use jQuery to bind a `submit` event handler.

**Hint:**
```javascript
$('form').on('submit', function(event) {
  if ($('#movie_title').val().trim() === '') {
    event.preventDefault();
    // Show error message...
  }
});
```

### Exercise 2: Add AJAX Delete Confirmation
Modify the "Destroy" button to use AJAX instead of a full page reload. Show a success message in the popup after deletion.

### Exercise 3: Improve Accessibility
Run an accessibility audit using Chrome DevTools Lighthouse (F12 → Lighthouse → Accessibility). Fix any issues found to achieve a score of 90+.

### Exercise 4: Add Jasmine Tests
Set up Jasmine and write tests for the `MoviePopup.toggleSelectAll` function. Use `spyOn` to test the AJAX call in `getMovieInfo` without making a real network request.

### Exercise 5: Try fetch() Instead of $.ajax()
The `getMovieInfoWithFetch` function in `movie_popup.js` shows the fetch() alternative. Modify the click handler to use `fetch()` instead of `$.ajax()` and observe the difference.

---

## Additional Resources

- [jQuery API Documentation](https://api.jquery.com/)
- [MDN: Fetch API](https://developer.mozilla.org/en-US/docs/Web/API/Fetch_API)
- [W3C Web Content Accessibility Guidelines (WCAG)](https://www.w3.org/WAI/standards-guidelines/wcag/)
- [ARIA Authoring Practices](https://www.w3.org/WAI/ARIA/apg/)
- [Jasmine Documentation](https://jasmine.github.io/)
- [Chrome DevTools - Network Tab](https://developer.chrome.com/docs/devtools/network/)
- [ESaaS Textbook Chapter 6](https://www.saasbook.info/)
- [JavaScript, The Good Parts (Crockford)](https://www.oreilly.com/library/view/javascript-the-good/9780596517748/)
