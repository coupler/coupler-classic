Feature: managing projects

  Scenario: creating a project
    When I go to the projects page
    And I click the "New Project" link
    And I fill in the form:
      | Name        | My Project             |
      | Description | This is a test project |
    And I click the "Submit" button
    Then it should show me a confirmation notice
    And ask me to add a resource
