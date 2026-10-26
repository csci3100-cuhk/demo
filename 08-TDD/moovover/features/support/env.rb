ENV['RAILS_ENV'] = 'test'

require 'cucumber/rails'
require 'cucumber/rspec/doubles'
require 'database_cleaner/active_record'

# The search form uses ordinary HTML; no browser installation or server needed.
Capybara.default_driver = :rack_test

# cucumber-rails starts and cleans a transaction around each scenario.
DatabaseCleaner.strategy = :transaction

# Keep the same seam checks as RSpec. Stubs are reset after each scenario
# by cucumber/rspec/doubles, so canned results cannot leak into the next one.
RSpec::Mocks.configuration.verify_partial_doubles = true
