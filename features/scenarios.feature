Feature: managing scenarios

  Scenario: creating a scenario
    Given that I have created a project called "My Project"
    And that I have added the "People" resource
    When I go to the project page
    And I click the "Create scenario" link
    And I fill in the form:
      | Name             | Link by Last name |
      | Type             | Self-join         |
      | Resource(s)      | People            |
    And I click the "Submit" button
    Then it should show me a confirmation page
    And ask me to add matchers

  Scenario: creating a dual-join scenario
    Given that I have created a project called "My Project"
    And that I have added the "People" resource
    And that I have added the "Pets" resource
    When I go to the project page
    And I click the "Create scenario" link
    And I fill in the form:
      | Name             | Link by name |
      | Type             | Dual-join    |
      | Resource(s)      | People/Pets  |
    And I click the "Submit" button
    Then it should show me a confirmation page
    And ask me to add matchers

  Scenario: running a self-join scenario
    Given that I have created a project called "My Project"
    And that I have added the "People" resource
    And that I have created a scenario called "Link by Last name"
    And that I have added a "exact" matcher with these options:
      | People | field_name | last_name |
    When I go to the scenario page
    And I click the "Run Now" button
    And I click the "Yes" button
    Then it should start the linkage process
