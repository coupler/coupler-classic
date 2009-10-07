Feature: Coupler
  In order to do research based on linked data
  I want to have an easy step-by-step process
  to link databases together

  Scenario: creating a project
    When I go to the front page
    And I click the "create a project" link
    And I fill in the form
    And I click the "Submit" button
    Then it should show me a confirmation page
    And ask me to add a resource

  Scenario: adding a resource
    Given that I have created a project called "My Project"
    When I go to the project page
    And I click the "Add resource" link
    And I fill in the form
    And I click the "Submit" button
    Then it should show me a confirmation page
    And ask me to add transformations

  Scenario: transforming a resource
    Given that I have created a project called "My Project"
    And that I have added a resource called "Patients"
    When I go to the resource page
    And I click the "Transform" link next to the "first_name" field
    And I select the "downcase" option
    And I click the "Submit" button
