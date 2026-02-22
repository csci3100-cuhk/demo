Feature: display students in alpha order

  As an instructor
  So that I can quickly find a student in the list
  I want the students to be displayed in alphabetical order by last name

Scenario: list students in alpha order

  Given student "Shaohua Li" exists
  And   student "Alex Lam" exists
  When  I visit the list of all students
  Then  "Alex Lam" should appear before "Shaohua Li"

