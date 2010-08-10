Feature: managing resources
  Background:
    Given that I have created a project called "My Project"
    And that I have created a transformer called "My Transformer"

  Scenario: adding a resource
    Given that I have created a connection called "My Connection"
    When I go to the project page
    And I click the "Add resource" link
    And I choose a "Database" resource
    And I fill in the form:
      | Name         | People        |
      | Connection   | My Connection |
      | Database (2) | fake_data     |
      | Table        | people        |
    And I click the "Submit" button
    Then it should show me a confirmation notice
    And ask me to choose which fields I wish to select

  Scenario: adding a resource and connection at the same time
    When I go to the project page
    And I click the "Add resource" link
    And I choose a "Database" resource
    And I fill in the form:
      | Name (1)     | Fake data |
      | Type         | MySQL     |
      | Host         | localhost |
      | Port         | 12345     |
      | Username     | coupler   |
      | Password     | cupla     |
      | Name (2)     | People    |
      | Database (2) | fake_data |
      | Table        | people    |
    And I click the "Submit" button
    Then it should show me a confirmation notice

  Scenario: adding a transformation
    Given that I have created a connection called "My Connection"
    And that I have added the "People" resource
    When I go to the resource page
    And I click on the hammer icon next to the "first_name" field
    And I fill in the form:
      | Transformer | My Transformer |
    And I click the "Finish" button
    Then it should show me a confirmation notice

  Scenario: deleting a transformation
    Given that I have created a connection called "My Connection"
    And that I have added the "People" resource
    And that I have added a transformation for "first_name"
    When I go to the resource page
    And I click on the cog icon next to the "first_name" field
    And I click the "Delete" link
    Then there should be no more transformations

  Scenario: transforming a resource
    Given that I have created a connection called "My Connection"
    And that I have added the "People" resource
    And that I have added a transformation for "first_name"
    When I go to the resource page
    And I click the "Transform now" button with confirmation
    Then it should start transforming
