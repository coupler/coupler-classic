require 'helper'

module CouplerUnitTests
  class TestDatabase < Coupler::Test::UnitTest
    def setup
      super
      @database = Coupler::Database
    end

    def test_connection
      assert_kind_of Sequel::JDBC::Database, @database

      expected = Coupler.connection_string('coupler')
      assert_equal expected, @database.uri
    end

    def test_migrate
      dir = File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "db", "migrate"))
      Sequel::Migrator.expects(:apply).with(@database, dir)
      @database.migrate!
    end
  end
end
