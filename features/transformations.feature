Feature: managing transformations

  Scenario: adding transformations
    Given that I have created a project called "My Project"
    And that I have added the "People" resource
    When I go to the resource page
    And I click the "Add transformation" link
    And I fill in the form:
      | Field       | first_name |
      | Transformer | downcaser  |
    And I click the "Submit" button
    Then it should take me back to the resource page

  Scenario: deleting a transformation
    Given that I have created a project called "My Project"
    And that I have added the "People" resource
    And that I have added a "downcaser" transformation for "first_name"
    When I go to the resource page
    And I click the "Delete" link
    Then there should be no more transformations
