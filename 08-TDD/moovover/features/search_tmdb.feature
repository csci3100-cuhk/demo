Feature: Look up a movie in TMDb
  As a moviegoer
  So that I can find movie information without entering it manually
  I want to search TMDb by title

  Scenario: Find a matching movie
    Given TMDb has a movie titled "Hardware" for the search "hardware"
    And I am on the movies page
    When I search TMDb for "hardware"
    Then I should see the TMDb search results
    And the results should include "Hardware"

  Scenario: No movies match
    Given TMDb has no movies for the search "no-such-film"
    And I am on the movies page
    When I search TMDb for "no-such-film"
    Then I should see the TMDb search results
    And I should see that no movies were found
