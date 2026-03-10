# Pin npm packages by running ./bin/importmap
# ESaaS §6.1 - Each HTML page loads JS via the importmap (Rails 7's approach)
# The importmap approach uses ES modules instead of bundling (Webpack/esbuild)

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"

# Custom JavaScript for Lecture 6 demos
# Note: movie_popup.js uses jQuery (loaded via CDN in the layout)
# and is a global script rather than an ES module, so it runs directly.
pin "movie_popup"
