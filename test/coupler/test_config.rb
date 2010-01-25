require File.dirname(__FILE__) + "/../helper"

module Coupler
  class TestConfig < ActiveSupport::TestCase
    def test_connection_string
      assert_equal(
        "jdbc:mysql://localhost:12345/ponies?user=coupler&password=cupla",
        Config.connection_string("ponies")
      )

      assert_equal(
        "jdbc:mysql://localhost:12345/ponies?user=coupler&password=cupla&createDatabaseIfNotExist=true",
        Config.connection_string("ponies", :create_database => true)
      )
    end
  end
end
