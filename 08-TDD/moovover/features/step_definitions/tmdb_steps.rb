# Only replace the external TMDb boundary. The form, route, controller,
# and rendered results are real; do not stub them to make a scenario pass.
Given('TMDb has a movie titled {string} for the search {string}') do |title, query|
  results = [Movie.new(title: title)]
  allow(Movie).to receive(:find_in_tmdb).with(query).and_return(results)
end

Given('TMDb has no movies for the search {string}') do |query|
  allow(Movie).to receive(:find_in_tmdb).with(query).and_return([])
end

Given('I am on the movies page') do
  visit movies_path
end

When('I search TMDb for {string}') do |query|
  fill_in 'Search Terms', with: query
  click_button 'Search TMDb'
end

Then('I should see the TMDb search results') do
  expect(page).to have_css('h1', text: 'TMDb Search Results')
end

Then('the results should include {string}') do |title|
  expect(page).to have_css('li', text: title, exact_text: true)
end

Then('I should see that no movies were found') do
  expect(page).to have_content('No results to display.')
end
