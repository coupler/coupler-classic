Feature: managing transformations

  Background:
    Given that I have created a connection called "My Connection"
    And that I have created a transformer called "My Transformer"
    And that I have created a project called "My Project"
    And that I have added the "People" resource

  Scenario: adding transformations
    When I go to the transformations page
    And I click the "New transformation" link
    And I fill in the form:
      | Field       | first_name     |
      | Transformer | My Transformer |
    And I click the "Submit" button
    Then it should show me a confirmation notice

  Scenario: deleting a transformation
    Given that I have added a transformation for "first_name"
    When I go to the transformations page
    And I click the "Delete" link
    Then there should be no more transformations
