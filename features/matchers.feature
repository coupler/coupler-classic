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
    And I select "Field" as the first type
    And I select "last_name" for "People 1" as the first value
    And I select "Field" as the second type
    And I select "last_name" for "People 2" as the second value
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
    And I select "Field" as the first type
    And I select "last_name" for "People" as the first value
    And I select "Field" as the second type
    And I select "owner_last_name" for "Pets" as the second value
    And I click the "Add" button
    And I click the "Submit" button
    Then it should take me back to the scenario page
    And it should show me a confirmation notice
