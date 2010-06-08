Feature: managing scenarios
  Background:
    Given that I have created a connection called "My Connection"
    And that I have created a project called "My Project"
    And that I have added the "People" resource

  Scenario: creating a self-linkage scenario
    When I go to the project page
    And I click the "Create scenario" link
    And I fill in the form:
      | Name | Link by Last name |
    And I click the "People" resource
    And I click the "Submit" button
    Then it should show me a confirmation notice
    And ask me to add matchers

  Scenario: creating a dual-linkage scenario
    Given that I have added the "Pets" resource
    When I go to the project page
    And I click the "Create scenario" link
    And I fill in the form:
      | Name | Link by name |
    And I click the "People" resource
    And I click the "Pets" resource
    And I click the "Submit" button
    Then it should show me a confirmation notice
    And ask me to add matchers

  Scenario: running a self-linkage scenario
    Given that I have created a self-linkage scenario called "Link by Last name"
    And that I have added a matcher with these options:
      | Type 1 | Value 1   | Operator | Type 2 | Value 2   |
      | field  | last_name | equals   | field  | last_name |
    When I go to the scenario page
    And I click the "Run now" button with confirmation
    Then it should start the linkage process

  Scenario: running a scenario with a non-equality matcher
    Given that I have created a self-linkage scenario called "Link by Last name"
    And that I have added a matcher with these options:
      | Type 1 | Value 1   | Operator       | Type 2 | Value 2   |
      | field  | last_name | does_not_equal | field  | last_name |
    When I go to the scenario page
    And I click the "Run now" button with confirmation
    Then it should start the linkage process
