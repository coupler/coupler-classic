require File.dirname(__FILE__) + "/../helper"

module Coupler
  class TestDatabase < Test::Unit::TestCase
    def setup
      super
      @database = Coupler::Database.instance
    end

    def test_connection
      assert_kind_of Sequel::JDBC::Database, @database.__getobj__

      expected = Config.connection_string("coupler_test", :create_database => true)
      assert_equal expected, @database.uri
    end

    def test_migrate
      dir = File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "db", "migrate"))
      Sequel::Migrator.expects(:apply).with(@database.__getobj__, dir)
      @database.migrate!
    end
  end
end
