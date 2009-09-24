Feature: Configuring
  In order to use coupler
  I need to configure it first

  Scenario: databases
    Given that I am viewing "/databases"
    When I click "New database"
    And I create a new database called "foo"
    Then that database should exist

  Scenario: resources
    Given that I have created a database called "foo"
    And that I am viewing "/resources"
    When I click "New resource"
    And I create a new resource on database "foo" and table "bar"
    Then that resource should exist
