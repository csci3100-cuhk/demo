// ============================================================
// MoovOver - JavaScript Demo (ESaaS Chapter 6)
// ============================================================
//
// This file demonstrates the key JavaScript concepts from Lecture 6:
//   §6.1-6.2: JavaScript basics, scope, modules
//   §6.3:     Functions as first-class objects, closures, arrow functions
//   §6.4:     jQuery & DOM manipulation
//   §6.5:     Accessibility (a11y) with JavaScript
//   §6.6:     Events & Callbacks
//   §6.7:     AJAX - Asynchronous JavaScript And XML
//
// IMPORTANT: We use the "module pattern" (ESaaS §6.2) to avoid polluting
// the global namespace. MoviePopup is the single global variable whose
// properties are our functions & attributes.

// ============================================================
// §6.2 - Variable Scope & The Module Pattern
// ============================================================
// Best practice: create a module — a global variable that is an object
// whose properties are your functions & attributes.
// This avoids polluting the global scope (window object).

let MoviePopup = {
  // ============================================================
  // §6.6 - Events & Callbacks: The Setup Function
  // ============================================================
  // Calling jQuery #3: Pass a function to $() to call it when DOM is ready.
  // jQuery(function() { ... }) is an alias for $(document).ready(function() { ... })
  //
  // The setup function:
  //   1. Identifies elements to interact with (using jQuery selectors)
  //   2. Binds event handlers to those elements
  //   3. Prepares any hidden UI elements

  setup: function() {
    // Cache jQuery selectors for efficiency (avoid repeated DOM lookups)
    // §6.4 - Calling jQuery #1: Select DOM elements with CSS selectors
    MoviePopup.$popup = $('#movie-popup');
    MoviePopup.$popupBody = $('#movie-popup-body');
    MoviePopup.$closeBtn = $('#movie-popup-close');

    // §6.6 - Bind event handlers
    // .on(event, handler) binds a handler function for a particular event type
    // Common events: click, submit, change, keypress, mouseenter, mouseleave

    // Bind close button click
    MoviePopup.$closeBtn.on('click', MoviePopup.hidePopup);

    // Bind Escape key to close popup (Accessibility - ESaaS §6.5)
    // Keyboard navigation: users should be able to dismiss dialogs with Escape
    $(document).on('keydown', function(event) {
      if (event.key === 'Escape' && MoviePopup.$popup.is(':visible')) {
        MoviePopup.hidePopup();
      }
    });

    // §6.6 - Event Delegation
    // Use event delegation for dynamically-added elements.
    // Bind on a parent element, filter by selector.
    // This handles clicks on .movie-popup-link elements even if they're
    // added to the DOM after setup() runs.
    $(document).on('click', '.movie-popup-link', MoviePopup.getMovieInfo);

    // Bind "Select All" checkbox (if it exists on this page)
    $('#select-all-movies').on('change', MoviePopup.toggleSelectAll);

    console.log('MoviePopup setup complete');
  },

  // ============================================================
  // §6.7 - AJAX: Asynchronous JavaScript And XML
  // ============================================================
  // AJAX allows us to make HTTP requests to the server without
  // triggering a full page reload. The flow:
  //   1. User clicks a link/button (event)
  //   2. JavaScript intercepts the event (handler)
  //   3. JS makes an HTTP request in the background ($.ajax / fetch)
  //   4. Server processes request, returns data (JSON, HTML partial, etc.)
  //   5. JS callback receives data and updates DOM
  //
  // §6.7 - Controller action can detect AJAX requests:
  //   request.xhr?  →  true if request is AJAX
  //   respond_to { |format| format.json { ... } }

  getMovieInfo: function(event) {
    // Prevent the default link behavior (navigating to a new page)
    // §6.6 - If handler returns false or calls preventDefault(),
    // the browser's default action is suppressed.
    event.preventDefault();

    // §6.4 - $(this) wraps the native DOM element with jQuery powers
    // .data('movie-id') reads the data-movie-id HTML attribute
    let $link = $(event.currentTarget);
    let movieId = $link.data('movie-id');
    let movieTitle = $link.text();

    // Show loading state (Progressive Enhancement - §6.1)
    MoviePopup.showPopup();
    MoviePopup.$popupBody.html(
      '<div class="text-center"><p>Loading info for <strong>' +
      movieTitle + '</strong>...</p>' +
      '<div class="spinner-border text-primary" role="status">' +
      '<span class="visually-hidden">Loading...</span></div></div>'
    );

    // ============================================================
    // §6.7 - The jQuery AJAX call
    // ============================================================
    // $.ajax({ type, url, timeout, success, error })
    //
    // The server responds based on the requested format:
    //   format.json → returns JSON data
    //   format.html → returns HTML (partial or full page)
    //
    // We request JSON here, then build the display in the callback.

    $.ajax({
      type: 'GET',
      url: '/movies/' + movieId + '.json',
      timeout: 5000,  // 5 second timeout
      // §6.3 - Arrow functions: concise syntax for callbacks
      // (response) => { ... } is shorthand for function(response) { ... }
      success: (response) => {
        // §6.7 - Callback receives server response
        // Unpack JSON and modify DOM
        MoviePopup.showMovieData(response);
      },
      error: (xhr, status, error) => {
        MoviePopup.$popupBody.html(
          '<div class="alert alert-danger" role="alert">' +
          '<strong>Error loading movie info.</strong> ' +
          'Status: ' + status +
          '</div>'
        );
      }
    });
  },

  // ============================================================
  // Alternative: Using fetch() instead of $.ajax()
  // ============================================================
  // Modern JavaScript provides the fetch() API as an alternative to $.ajax().
  // fetch() returns a Promise, which supports .then() chaining.
  //
  // Example (not used here, but shown for comparison):
  //
  //   fetch('/movies/' + movieId + '.json')
  //     .then((response) => {
  //       if (response.ok) { return response.json(); }
  //       throw new Error('Something went wrong');
  //     })
  //     .then((data) => { MoviePopup.showMovieData(data); })
  //     .catch((error) => { console.log(error); });

  getMovieInfoWithFetch: function(event) {
    event.preventDefault();
    let $link = $(event.currentTarget);
    let movieId = $link.data('movie-id');

    MoviePopup.showPopup();
    MoviePopup.$popupBody.html('<p>Loading...</p>');

    // §6.7 - JavaScript's native fetch() API
    fetch('/movies/' + movieId + '.json')
      .then((response) => {
        if (response.ok) {
          return response.json();
        }
        throw new Error('Network response was not ok');
      })
      .then((data) => {
        MoviePopup.showMovieData(data);
      })
      .catch((error) => {
        MoviePopup.$popupBody.html(
          '<div class="alert alert-danger">Error: ' + error.message + '</div>'
        );
      });
  },

  // ============================================================
  // §6.4 - DOM Manipulation with jQuery
  // ============================================================
  // jQuery methods for inspecting/modifying DOM elements:
  //   .text() / .html()     - get/set text or HTML content
  //   .attr('name')         - get/set attributes
  //   .addClass() / .removeClass() / .toggleClass()
  //   .show() / .hide()     - display/hide elements
  //   .css()                - get/set CSS properties

  showMovieData: function(movieData) {
    // §6.4 - Calling jQuery #2: Create new DOM elements with $('<tag>')
    // These elements have jQuery superpowers but aren't added to page yet.
    let html = '<h4>' + MoviePopup.escapeHtml(movieData.title) + '</h4>';
    html += '<dl class="row">';

    if (movieData.rating) {
      html += '<dt class="col-sm-4">Rating</dt>';
      html += '<dd class="col-sm-8"><span class="badge bg-info">' +
              MoviePopup.escapeHtml(movieData.rating) + '</span></dd>';
    }

    if (movieData.description) {
      html += '<dt class="col-sm-4">Description</dt>';
      html += '<dd class="col-sm-8">' + MoviePopup.escapeHtml(movieData.description) + '</dd>';
    }

    if (movieData.release_date) {
      html += '<dt class="col-sm-4">Release Date</dt>';
      html += '<dd class="col-sm-8">' + MoviePopup.escapeHtml(movieData.release_date) + '</dd>';
    }

    html += '</dl>';
    html += '<a href="/movies/' + movieData.id + '" class="btn btn-primary btn-sm">View Full Details</a>';

    // §6.4 - .html() replaces the inner HTML of the selected element
    MoviePopup.$popupBody.html(html);
  },

  // ============================================================
  // Show/Hide Popup with Accessibility (ESaaS §6.5)
  // ============================================================
  // Using JavaScript to Enhance Pages:
  //   - aria-expanded describes if something collapsible is visible
  //   - aria-hidden indicates if content is hidden from AT
  //   - Use JS to keep ARIA attributes in sync with visual state

  showPopup: function() {
    // §6.4 - .show() makes element visible (sets display: block)
    MoviePopup.$popup.show();
    // §6.5 - Keep ARIA attributes in sync with visual state
    MoviePopup.$popup.attr('aria-hidden', 'false');
    // Move focus to popup for keyboard users (§6.5)
    MoviePopup.$closeBtn.focus();
  },

  hidePopup: function() {
    // §6.4 - .hide() makes element invisible (sets display: none)
    MoviePopup.$popup.hide();
    // §6.5 - Update ARIA attribute
    MoviePopup.$popup.attr('aria-hidden', 'true');
    // Return focus to the element that opened the popup (§6.5)
    if (MoviePopup._lastFocused) {
      MoviePopup._lastFocused.focus();
    }
  },

  // ============================================================
  // §6.6 - Events: "Select All" Toggle
  // ============================================================
  // Demonstrates: event handling, DOM traversal, jQuery selectors,
  // and the :checked pseudo-selector.

  toggleSelectAll: function() {
    // §6.4 - .is(':checked') inspects element state
    let isChecked = $(this).is(':checked');
    // §6.4 - Select multiple elements and set their 'checked' property
    // .prop() sets a DOM property (vs .attr() which sets an HTML attribute)
    $('.movie-checkbox').prop('checked', isChecked);
    // Update the count display
    MoviePopup.updateSelectedCount();
  },

  updateSelectedCount: function() {
    // §6.4 - Using jQuery selectors with pseudo-classes
    let count = $('.movie-checkbox:checked').length;
    let total = $('.movie-checkbox').length;
    let $counter = $('#selected-count');
    if (count > 0) {
      $counter.text(count + ' of ' + total + ' selected').show();
    } else {
      $counter.hide();
    }
  },

  // ============================================================
  // Utility: HTML escaping (prevent XSS)
  // ============================================================

  escapeHtml: function(text) {
    if (!text) return '';
    let div = document.createElement('div');
    div.appendChild(document.createTextNode(text));
    return div.innerHTML;
  }
};

// ============================================================
// §6.6 - Calling jQuery #3: $(function) runs when DOM is ready
// ============================================================
// This is equivalent to: $(document).ready(MoviePopup.setup)
// It ensures the page is completely loaded before we try to
// find and manipulate DOM elements.
//
// IMPORTANT: Rails 7 uses Turbo Drive (Hotwire), which navigates
// between pages by replacing the <body> WITHOUT a full page reload.
// This means $(document).ready() only fires ONCE on the initial load.
// After a Turbo navigation (e.g. clicking "Back to movies"), the DOM
// elements are replaced but $(document).ready() does NOT re-fire,
// so our cached jQuery objects ($popup, $popupBody, etc.) become
// stale references to elements that no longer exist in the DOM.
//
// Solution: Listen for the 'turbo:load' event, which fires on EVERY
// page visit (both initial load and Turbo navigations).
// We also keep $(MoviePopup.setup) as a fallback for the initial load
// in case Turbo hasn't initialized yet.

$(MoviePopup.setup);

// Re-run setup after every Turbo navigation so that:
//   1. Cached jQuery selectors ($popup, $closeBtn, etc.) point to
//      the NEW DOM elements that Turbo just inserted
//   2. Event handlers bound directly on elements (not via delegation)
//      are re-attached to the new elements
document.addEventListener('turbo:load', MoviePopup.setup);
