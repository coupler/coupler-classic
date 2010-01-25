# Don't require test/helper.rb here, since it needs to be standalone
require 'test/unit'
require 'java'
require 'active_support'
require 'active_support/test_case'
require File.join(File.dirname(__FILE__), '..', '..', 'lib', 'coupler', 'server')

module Coupler
  class TestServer < ActiveSupport::TestCase
    def setup
      @server = Server.instance
    end

    def test_connection_string
      assert_equal(
        "jdbc:mysql://localhost:12345/ponies?user=coupler&password=cupla",
        @server.connection_string("ponies")
      )

      assert_equal(
        "jdbc:mysql://localhost:12345/ponies?user=coupler&password=cupla&createDatabaseIfNotExist=true",
        @server.connection_string("ponies", :create_database => true)
      )
    end
  end
end
