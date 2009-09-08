Feature: Configuring
  In order to link some databases
  I want to configure coupler first

  Scenario: resources
    Given that I am viewing "/resources/new"
    When I add a "mysql" resource
    Then that resource should be available
