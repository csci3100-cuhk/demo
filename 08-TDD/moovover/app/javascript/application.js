// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
//
// ESaaS §6.1 - JavaScript: The Big Picture
// This is the main JS entry point for the application.
// Rails 7 uses importmap for ES module imports (no bundler needed).
// Each import statement loads a pinned module from config/importmap.rb.

import "@hotwired/turbo-rails"
import "controllers"

// ESaaS §6.6, §6.7 - Our custom JavaScript for movie popup (jQuery + AJAX)
// This module uses jQuery ($) for DOM manipulation and AJAX calls.
// jQuery is loaded via CDN in the application layout.
import "movie_popup"
