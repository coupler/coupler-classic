require File.dirname(__FILE__) + '/../../helper'

module Coupler
  module Models
    class TestResource < ActiveSupport::TestCase
      def setup
        @config = Coupler::Config.instance
        @server = Coupler::Server.instance
        @inf = Sequel.connect(@server.connection_string("information_schema"))
      end

      def test_sequel_model
        assert_equal Sequel::Model, Resource.superclass
        assert_equal :resources, Resource.table_name
      end

      def test_many_to_one_projects
        assert_respond_to Resource.new, :project
      end

      def test_one_to_many_transformations
        assert_respond_to Resource.new, :transformations
      end

      def test_many_to_many_scenarios
        assert_respond_to Resource.new, :scenarios
      end

      def test_requires_name
        resource = Factory.build(:resource, :name => nil)
        assert !resource.valid?

        resource.name = ""
        assert !resource.valid?
      end

      def test_requires_unique_name_across_projects
        project = Factory.create(:project)
        resource_1 = Factory.create(:resource, :name => "avast", :project => project)
        resource_2 = Factory.build(:resource, :name => "avast", :project => project)
        assert !resource_2.valid?
      end

      def test_required_unique_name_on_update
        project = Factory.create(:project)
        resource_1 = Factory.create(:resource, :name => "avast", :project => project)
        resource_2 = Factory.create(:resource, :name => "ahoy", :project => project)
        resource_1.name = "ahoy"
        assert !resource_1.valid?, "Resource wasn't invalid"
      end

      def test_updating
        project = Factory.create(:project)
        resource = Factory.create(:resource, :name => "avast", :project => project)
        resource.save!
      end

      def test_requires_valid_database_connection
        resource = Factory.build(:resource, :database_name => "blargh")
        assert !resource.valid?, "Resource wasn't invalid"
      end

      def test_requires_non_empty_database_name
        resource = Factory.build(:resource, :database_name => nil)
        assert !resource.valid?, "Resource wasn't invalid"
      end

      def test_requires_non_empty_table_name
        resource = Factory.build(:resource, :table_name => nil)
        assert !resource.valid?, "Resource wasn't invalid"
      end

      def test_requires_valid_table_name
        resource = Factory.build(:resource, :table_name => "blargh")
        assert !resource.valid?, "Resource wasn't invalid"
      end

      def test_sets_slug_from_name
        resource = Factory(:resource, :name => 'Foo bar')
        assert_equal "foo_bar", resource.slug
      end

      def test_requires_unique_slug_across_projects
        project = Factory(:project)
        resource_1 = Factory(:resource, :slug => 'pants')
        resource_2 = Factory.build(:resource, :name => 'foo', :slug => 'pants')
        assert !resource_2.valid?

        resource_2.slug = "roflslam"
        assert resource_2.valid?
        resource_2.save

        resource_2.slug = "pants"
        assert !resource_2.valid?
      end

      def test_mysql_source_connection
        resource = Factory.create(:resource, {
          :name => "testing",
          :adapter => "mysql",
          :host => "localhost",
          :port => 12345,
          :username => "coupler",
          :password => "cupla",
          :database_name => "fake_data",
          :table_name => "people"
        })
        assert_kind_of Sequel::JDBC::Database, resource.source_connection
        assert resource.source_connection.test_connection
      end

      def test_source_dataset
        resource = Factory.create(:resource)
        dataset = resource.source_dataset
        assert_kind_of Sequel::Dataset, dataset
        assert_equal "SELECT * FROM `people`", dataset.select_sql
      end

      def test_source_schema
        resource = Factory.create(:resource)
        expected = [[:id, {:allow_null=>false, :default=>nil, :primary_key=>true, :db_type=>"int(11)", :type=>:integer, :ruby_default=>nil}], [:first_name, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"varchar(255)", :type=>:string, :ruby_default=>nil}], [:last_name, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"varchar(255)", :type=>:string, :ruby_default=>nil}]]
        assert_equal expected, resource.source_schema
      end

      def test_local_connection_creates_database
        databases = @config["SHOW DATABASES"].collect { |x| x[:Database] }
        @config.run("DROP DATABASE roflsauce")  if databases.include?("rolfsauce")

        project = Factory(:project, :name => "roflsauce")
        resource = Factory(:resource, :name => "pants", :project => project)

        connection = resource.local_connection
        assert_kind_of Sequel::JDBC::Database, connection
        assert connection.test_connection
      end

      def test_local_dataset
        @inf.execute("DROP DATABASE IF EXISTS local_dataset_test")

        project = Factory(:project, :name => "local_dataset test")
        resource = Factory(:resource, :name => "Resource 1", :project => project)
        transformation = Factory(:transformation, {
          :resource => resource, :transformer_name => "downcaser",
          :field_name => "first_name"
        })

        local_dataset = resource.local_dataset

        local_connection = Sequel.connect(Coupler::Server.instance.connection_string("local_dataset_test"))
        assert local_connection.tables.include?(:resource_1)

        expected_schema = [[:id, {:allow_null=>false, :default=>nil, :primary_key=>true, :db_type=>"int(11)", :type=>:integer, :ruby_default=>nil}], [:first_name, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"varchar(255)", :type=>:string, :ruby_default=>nil}], [:last_name, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"varchar(255)", :type=>:string, :ruby_default=>nil}]]
        assert_equal expected_schema, local_connection.schema(:resource_1)

        assert_equal local_connection[:resource_1].select_sql, local_dataset.select_sql
      end

      def test_transform
        project = Factory(:project, :name => "Awesome Test Project")
        resource = Factory(:resource, :name => "pants", :project => project)
        transformation = Factory(:transformation, {
          :resource => resource, :transformer_name => "downcaser",
          :field_name => "first_name"
        })

        original_row = resource.source_dataset.first
        Timecop.freeze(Time.now) do
          resource.transform!
          assert_equal Time.now, resource.transformed_at
        end

        result_db = Sequel.connect(Coupler::Server.instance.connection_string("awesome_test_project"))
        assert result_db.tables.include?(:pants)

        expected = [[:id, {:allow_null=>false, :default=>nil, :primary_key=>true, :db_type=>"int(11)", :type=>:integer, :ruby_default=>nil}], [:first_name, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"varchar(255)", :type=>:string, :ruby_default=>nil}], [:last_name, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"varchar(255)", :type=>:string, :ruby_default=>nil}]]
        assert_equal expected, result_db.schema(:pants)

        result_set = result_db[:pants]
        changed_row = result_set[:id => original_row[:id]]
        assert_equal original_row[:first_name].downcase, changed_row[:first_name]

        assert_equal "ok", resource.status
      end

      def test_initial_status
        resource = Factory(:resource)
        assert_equal "ok", resource.status
      end

      def test_update_status_changes_status_after_adding_first_transformation
        resource = Factory(:resource)
        transformation = Factory(:transformation, :resource => resource)
        resource.update(:status => "ok")  # just to make sure
        resource.update_status!
        assert_equal "out of date", resource.status
      end

      def test_update_status_changes_status_when_transformed_at_is_old
        resource = Factory(:resource, :transformed_at => Time.now - 20)
        transformation = Factory(:transformation, :resource => resource)
        resource.update(:status => "ok")  # just to make sure
        resource.update_status!
        assert_equal "out of date", resource.status
      end

      def test_update_status_changes_status_when_transformations_are_updated
        resource = Factory(:resource, :transformed_at => Time.now - 20)
        transformation = Factory(:transformation, :resource => resource)
        resource.update(:status => "ok")  # just to make sure
        transformation.update(:field_name => "blahblah")
        resource.update_status!
        assert_equal "out of date", resource.status
      end

      def test_update_status_changes_status_when_transformations_are_removed
        resource = Factory(:resource, :transformed_at => Time.now - 20)
        transformation = Factory(:transformation, :resource => resource)
        resource.update(:status => "out of date")  # just to make sure
        transformation.destroy
        resource.update_status!
        assert_equal "ok", resource.status
      end

      def test_final_connection_is_source_connection_when_no_transformations
        resource = Factory(:resource)
        assert_equal resource.source_connection, resource.final_connection
      end

      def test_final_connection_is_local_connection_when_transformations
        resource = Factory(:resource)
        transformation = Factory(:transformation, :resource => resource)
        assert_equal resource.local_connection, resource.final_connection
      end

      def test_final_dataset_is_source_dataset_when_no_transformations
        resource = Factory(:resource)
        assert_equal resource.source_dataset, resource.final_dataset
      end

      def test_final_dataset_is_local_dataset_when_transformations
        resource = Factory(:resource)
        transformation = Factory(:transformation, :resource => resource)
        assert_equal resource.local_dataset, resource.final_dataset
      end
    end
  end
end
