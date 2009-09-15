Feature: Configuring
  In order to link some databases
  I want to configure coupler first

  Scenario: databases
    Given that I am viewing "/databases"
    When I click "New database"
    And I create a new database called "foo"
    Then that database should exist
