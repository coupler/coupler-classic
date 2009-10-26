require File.dirname(__FILE__) + '/../../helper'

module Coupler
  module Models
    class TestResource < ActiveSupport::TestCase
      def setup
        Project.delete
        Resource.delete

        @database = mock("sequel database")
        @database.stubs(:test_connection).returns(true)
        @database.stubs(:tables).returns([:people])
        ::Sequel.stubs(:connect).returns(@database)
      end

      def test_sequel_model
        assert_equal ::Sequel::Model, Resource.superclass
        assert_equal :resources, Resource.table_name
      end

      def test_many_to_one_projects
        assert_respond_to Resource.new, :project
      end

      def test_requires_name
        resource = ::Factory.create(:resource, :name => nil)
        assert !resource.valid?

        resource.name = ""
        assert !resource.valid?
      end

      def test_requires_unique_name_across_projects
        project = ::Factory.create(:project)
        resource_1 = ::Factory.create(:resource, :name => "avast", :project => project)
        resource_2 = ::Factory.build(:resource, :name => "avast", :project => project)
        assert !resource_2.valid?
      end

      def test_requires_valid_database_connection
        @database.expects(:test_connection).raises(::Sequel::DatabaseConnectionError)

        resource = ::Factory.build(:resource)
        assert !resource.valid?, "Resource wasn't invalid"
      end

      def test_requires_non_empty_database_name
        resource = ::Factory.build(:resource, :database_name => nil)
        assert !resource.valid?, "Resource wasn't invalid"
      end

      def test_requires_non_empty_table_name
        resource = ::Factory.build(:resource, :table_name => nil)
        assert !resource.valid?, "Resource wasn't invalid"
      end

      def test_requires_valid_table_name
        @database.expects(:tables).returns([])

        resource = ::Factory.build(:resource)
        assert !resource.valid?, "Resource wasn't invalid"
      end

      def test_mysql_connection
        ::Sequel.expects(:connect).with("jdbc:mysql://localhost/coupler_test?user=coupler&password=cupla").returns(@database)
        resource = ::Factory.create(:resource, {
          :name => "testing",
          :adapter => "mysql",
          :host => "localhost",
          :port => 3306,
          :username => "coupler",
          :password => "cupla",
          :database_name => "coupler_test",
          :table_name => "people"
        })
        resource.connection
      end

      def test_dataset
        resource = ::Factory.create(:resource)
        dataset = mock("sequal dataset")
        @database.expects(:[]).with('people').returns(dataset)
        assert_equal dataset, resource.dataset
      end

      def test_schema
        resource = ::Factory.create(:resource)
        schema = mock("sequel schema")
        @database.expects(:schema).with('people').returns(schema)
        assert_equal schema, resource.schema
      end
    end
  end
end
