require 'helper'

module Coupler
  class TestDatabase < Coupler::Test::UnitTest
    def setup
      super
      @database = Coupler::Database.instance
    end

    def test_connection
      assert_kind_of Sequel::JDBC::Database, @database.__getobj__

      expected = Base.connection_string('coupler')
      assert_equal expected, @database.uri
    end

    def test_migrate
      dir = File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "db", "migrate"))
      Sequel::Migrator.expects(:apply).with(@database.__getobj__, dir)
      @database.migrate!
    end
  end
end