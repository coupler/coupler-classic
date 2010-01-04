require File.dirname(__FILE__) + '/../../helper'

module Coupler
  module Models
    class TestResource < ActiveSupport::TestCase
      def setup
        @config = Coupler::Config.instance
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

      def test_mysql_connection
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
        assert_kind_of Sequel::JDBC::Database, resource.connection
        assert resource.connection.test_connection
      end

      def test_dataset
        resource = Factory.create(:resource)
        dataset = resource.dataset
        assert_kind_of Sequel::Dataset, dataset
        assert_equal "SELECT * FROM `people`", dataset.select_sql
      end

      def test_schema
        resource = Factory.create(:resource)
        expected = [[:id, {:allow_null=>false, :default=>nil, :primary_key=>true, :db_type=>"int(11)", :type=>:integer, :ruby_default=>nil}], [:first_name, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"varchar(255)", :type=>:string, :ruby_default=>nil}], [:last_name, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"varchar(255)", :type=>:string, :ruby_default=>nil}]]
        assert_equal expected, resource.schema
      end

      #def test_transform
        #Mocha::Mockery.instance.stubba.unstub_all
        #project = Factory(:project, :name => "roflsauce")
        #resource = Factory(:resource, :name => "pants", :project => project)
        #transformation = Factory(:transformation, {
          #:resource => resource, :transformer_name => "downcaser",
          #:field_name => "first_name"
        #})
        #row = resource.dataset[:id => 1]
        #resource.transform!

        #result_set = Sequel.connect(Coupler::Server.instance.connection_string("roflsauce[pants]"))
        #assert result_set.test_connection
        #assert_equal row[:first_name].downcase, result_set[:id => 1][:first_name]
      #end

      def test_result_connection_creates_database
        databases = @config["SHOW DATABASES"].collect { |x| x[:Database] }
        @config.run("DROP DATABASE roflsauce")  if databases.include?("rolfsauce")

        project = Factory(:project, :name => "roflsauce")
        resource = Factory(:resource, :name => "pants", :project => project)

        connection = resource.result_connection
        assert_kind_of Sequel::JDBC::Database, connection
        assert connection.test_connection
      end

      def test_transform
        project = Factory(:project, :name => "Awesome Test Project")
        resource = Factory(:resource, :name => "pants", :project => project)
        transformation = Factory(:transformation, {
          :resource => resource, :transformer_name => "downcaser",
          :field_name => "first_name"
        })

        original_row = resource.dataset.first
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
      end
    end
  end
end
