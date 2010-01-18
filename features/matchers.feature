Feature: managing matchers

  Scenario: creating a matcher
    Given that I have created a project called "My Project"
    And that I have added a resource called "People"
    And that I have created a scenario called "Link by Last name"
    When I go to the scenario page
    And I click the "Add matcher" link
    And I fill in the form:
      | Comparator | exact     |
      | Field      | last_name |
    And I click the "Submit" button
    Then it should take me back to the scenario page
