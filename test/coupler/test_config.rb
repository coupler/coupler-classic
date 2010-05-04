require File.dirname(__FILE__) + "/../helper"

module Coupler
  class TestConfig < Test::Unit::TestCase
    def test_connection_string
      assert_equal(
        "jdbc:mysql://localhost:12345/ponies?user=coupler&password=cupla",
        Config.connection_string("ponies")
      )

      assert_equal(
        "jdbc:mysql://localhost:12345/ponies?user=coupler&password=cupla&createDatabaseIfNotExist=true",
        Config.connection_string("ponies", :create_database => true)
      )

      assert_equal(
        "jdbc:mysql://localhost:12345/ponies?user=coupler&password=cupla&createDatabaseIfNotExist=true&zeroDateTimeBehavior=convertToNull",
        Config.connection_string("ponies", :create_database => true, :zero_date_time_behavior => :convert_to_null)
      )
    end
  end
end
