Feature: Coupler
  In order to do research based on linked data
  I want to have an easy step-by-step process
  to link databases together

  Scenario: creating a project
    When I go to the front page
    And I click the "create a project" link
    And I fill in the form:
      | Name        | My Project             |
      | Description | This is a test project |
    And I click the "Submit" button
    Then it should show me a confirmation page
    And ask me to add a resource

  Scenario: adding a resource
    Given that I have created a project called "My Project"
    When I go to the project page
    And I click the "Add resource" link
    And I fill in the form:
      | Name     | People    |
      | Host     | localhost |
      | Port     | 12345     |
      | Username | coupler   |
      | Password | cupla     |
      | Database | fake_data |
      | Table    | people    |
    And I click the "Submit" button
    Then it should show me a confirmation page
    And ask me to add transformations

  Scenario: adding transformations
    Given that I have created a project called "My Project"
    And that I have added a resource called "People"
    When I go to the resource page
    And I click the "Add transformation" link
    And I fill in the form:
      | Field       | first_name |
      | Transformer | downcaser  |
    And I click the "Submit" button
    Then it should take me back to the resource page

  Scenario: transforming a resource
    Given that I have created a project called "My Project"
    And that I have added a resource called "People"
    And that I have added a "downcaser" transformation for "first_name"
    When I go to the resource page
    And I click the "Transform Now" button
    And I click the "Yes" button
    Then it should start transforming

  Scenario: creating a scenario
    Given that I have created a project called "My Project"
    And that I have added a resource called "People"
    When I go to the project page
    And I click the "Create scenario" link
    And I fill in the form:
      | Name             | Link by Last name |
      | Type             | Self-join         |
      | Resource         | People            |
      | Range            | 50-100            |
      | Combining Method | Sum               |
    And I click the "Submit" button
    Then it should show me a confirmation page
    And ask me to add matchers

  Scenario: adding a matcher
    Given that I have created a project called "My Project"
    And that I have added a resource called "People"
    And that I have created a scenario called "Link by Last name"
    When I go to the scenario page
    And I click the "Add matcher" link
    And I fill in the form:
      | Field | last_name |
      | Type  | Exact     |
    And I click the "Submit" button
    Then it should take me back to the scenario page

  Scenario: running a scenario
    Given that I have created a project called "My Project"
    And that I have added a resource called "People"
    And that I have created a scenario called "Link by Last name"
    And that I have added an "Exact" matcher for "last_name"
    When I go to the scenario page
    And I click the "Run" button
    And I click the "Yes" button
    Then it should start the linkage process
