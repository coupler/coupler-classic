Feature: running Coupler for the first time

  Scenario: with a database resource
    When I go to the front page
    And I click the "create a project" link
    And I fill in the form:
      | Name        | My Project               |
      | Description | This is my first project |
    And I click the "Submit" button
    And I click the "add a resource" link
    And I click the 
