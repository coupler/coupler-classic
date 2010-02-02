Feature: managing resources

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

  Scenario: transforming a resource
    Given that I have created a project called "My Project"
    And that I have added the "People" resource
    And that I have added a "downcaser" transformation for "first_name"
    When I go to the resource page
    And I click the "Transform Now" button
    And I click the "Yes" button
    Then it should start transforming
