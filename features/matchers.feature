Feature: managing matchers

  Scenario: creating a matcher
    Given that I have created a project called "My Project"
    And that I have added the "People" resource
    And that I have created a scenario called "Link by Last name"
    When I go to the scenario page
    And I click the "Add matcher" link
    And I fill in the form:
      | Comparator | exact     |
      | Field      | last_name |
    And I click the "Submit" button
    Then it should take me back to the scenario page

  Scenario: creating a matcher for a dual-join scenario
    Given that I have created a project called "My Project"
    And that I have added the "People" resource
    And that I have added the "Pets" resource
    And that I have created a dual-join scenario called "Link by name"
    When I go to the scenario page
    And I click the "Add matcher" link
    And I fill in the form:
      | Comparator       | exact           |
      | Field for People | last_name       |
      | Field for Pets   | owner_last_name |
    And I click the "Submit" button
    Then it should take me back to the scenario page
