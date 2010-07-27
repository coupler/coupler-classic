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

      assert_equal(
        "jdbc:mysql://localhost:12345/ponies?user=coupler&password=cupla&autoReconnect=true",
        Config.connection_string("ponies", :auto_reconnect => true)
      )
    end

    def test_setting_options
      Config.set(:database, :port, 37222)
      assert_equal 37222, Config.get(:database, :port)
    end

    def teardown
      Config.set(:database, :port, 12345)
      super
    end
  end
end
