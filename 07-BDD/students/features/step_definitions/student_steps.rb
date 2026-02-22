Given /^student "(.*) (.*)" exists$/ do |first,last|
  Student.create!(:first_name => first, :last_name => last, :sid_number => rand(10000))
end

When /^I visit the list of all students$/ do
  visit students_path  # alternatively, you can use visit "/students"
  save_page
end

Then /^"(.*) (.*)" should appear before "(.*) (.*)"$/ do |first1,last1, first2,last2|
  regex = /#{first1}.*#{last1}.*#{first2}.*#{last2}/m
  table = page.find('table#student-table')
  expect(table.text).to match(regex)
end
