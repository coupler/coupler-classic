require File.dirname(__FILE__) + '/../../helper'

module Coupler
  module Extensions
    class TestTransformations < ActiveSupport::TestCase
      def setup
        Models::Project.delete
        Models::Resource.delete

        @project = ::Factory.create(:project, :slug => "roflcopter")
        @database = mock("sequel database")
        @database.stubs(:test_connection).returns(true)
        @database.stubs(:tables).returns([:people])
        Models::Resource.any_instance.stubs(:connection).returns(@database)
        Models::Resource.any_instance.stubs(:schema).returns([[:id, {:allow_null=>false, :default=>nil, :primary_key=>true, :db_type=>"int(11)", :type=>:integer, :ruby_default=>nil}], [:first_name, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"varchar(50)", :type=>:string, :ruby_default=>nil}], [:last_name, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"varchar(50)", :type=>:string, :ruby_default=>nil}]])
      end

      def test_truth
      end
    end
  end
end
