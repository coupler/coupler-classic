Feature: managing connections

  Scenario: creating a connection
    When I go to the connections page
    And I click the "New Connection" link
    And I fill in the form:
      | Name     | Fake data |
      | Type     | MySQL     |
      | Host     | localhost |
      | Port     | 12345     |
      | Username | coupler   |
      | Password | cupla     |
    And I click the "Submit" button
    Then it should show me a confirmation notice

  Scenario: editing a connection
    Given that I have created a connection called "My Connection"
    When I go to the connections page
    And I click the "Edit" link
    And I change "Name" to "Server X"
    And I click the "Submit" button
    Then it should take me back to the connections page

  Scenario: changing a connection that orphans resources

  Scenario: deleting a connection

  Scenario: deleting a connection that orphans resources
