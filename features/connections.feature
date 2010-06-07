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
