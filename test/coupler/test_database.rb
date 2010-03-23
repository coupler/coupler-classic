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

    def test_create_schema
      [:projects, :resources, :transformations, :scenarios, :resources_scenarios, :matchers, :jobs].each do |name|
        @database.expects(:create_table).with(name)
      end
      @database.create_schema
    end
  end
end
