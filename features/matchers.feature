Feature: managing matchers

  Background:
    Given that I have created a connection called "My Connection"
    And that I have created a project called "My Project"
    And that I have added the "People" resource

  Scenario: creating a matcher for a self-linkage scenario
    Given that I have created a self-linkage scenario called "Link by Last name"
    When I go to the scenario page
    And I click the "Add matcher" link
    And I click the "Add comparison" link
    And I fill in the form:
      | lhs_type         | Field     |
      | lhs_value_select | last_name |
      | rhs_type         | Field     |
      | rhs_value_select | last_name |
    And I click the "Add" button
    And I click the "Submit" button
    Then it should take me back to the scenario page
    And it should show me a confirmation notice

  Scenario: creating a matcher for a dual-join scenario
    Given that I have added the "Pets" resource
    And that I have created a dual-linkage scenario called "Link by Last name"
    When I go to the scenario page
    And I click the "Add matcher" link
    And I click the "Add comparison" link
    And I fill in the form:
      | lhs_type         | Field           |
      | lhs_value_select | last_name       |
      | rhs_type         | Field           |
      | rhs_value_select | owner_last_name |
    And I click the "Add" button
    And I click the "Submit" button
    Then it should take me back to the scenario page
    And it should show me a confirmation notice
