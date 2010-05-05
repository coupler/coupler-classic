require File.dirname(__FILE__) + '/../../helper'

module Coupler
  module Models
    class TestResource < Test::Unit::TestCase
      def db(&block)
        Sequel.connect(Config.connection_string("information_schema"), &block)
      end

      def test_sequel_model
        assert_equal Sequel::Model, Resource.superclass
        assert_equal :resources, Resource.table_name
      end

      def test_many_to_one_connection
        assert_respond_to Resource.new, :connection
      end

      def test_many_to_one_project
        assert_respond_to Resource.new, :project
      end

      def test_one_to_many_transformations
        assert_respond_to Resource.new, :transformations
      end

      def test_one_to_many_jobs
        assert_respond_to Resource.new, :jobs
      end

      def test_one_to_many_fields
        assert_respond_to Resource.new, :fields
      end

      def test_one_to_many_selected_fields
        assert_respond_to Resource.new, :selected_fields
      end

      def test_nested_attributes_for_fields
        resource = Factory(:resource)
        field = resource.fields_dataset[:name => 'first_name']
        resource.update(:fields_attributes => [{:id => field.id, :is_selected => 0}])
        field.refresh
        assert field.is_selected == false || field.is_selected == 0
      end

      def test_rejects_new_fields_for_nested_attributes
        resource = Factory(:resource)
        count = resource.fields_dataset.count
        resource.update(:fields_attributes => [{:is_selected => 0}])
        assert_equal count, resource.fields_dataset.count
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
        resource_1 = Factory(:resource, :slug => 'pants', :project => project)
        resource_2 = Factory.build(:resource, :name => 'foo', :slug => 'pants', :project => project)
        assert !resource_2.valid?

        resource_2.slug = "roflslam"
        assert resource_2.valid?
        resource_2.save

        resource_2.slug = "pants"
        assert !resource_2.valid?
      end

      def test_requires_primary_key
        resource = Factory.build(:resource, :table_name => "no_primary_key")
        assert !resource.valid?
      end

      def test_requires_single_primary_key
        resource = Factory.build(:resource, :table_name => "two_primary_keys")
        assert !resource.valid?
      end

      def test_requires_integer_primary_key
        resource = Factory.build(:resource, :table_name => "string_primary_key")
        assert !resource.valid?
      end

      def test_sets_primary_key_field
        resource = Factory(:resource, :table_name => "avast_ye")
        assert_equal "arrr", resource.primary_key_name
      end

      def test_creates_fields
        connection = Factory(:connection)
        resource = Factory.build(:resource, :connection => connection)
        schema = [
          [:id, {:allow_null=>false, :default=>nil, :primary_key=>true, :db_type=>"int(11)", :type=>:integer, :ruby_default=>nil}],
          [:first_name, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"varchar(255)", :type=>:string, :ruby_default=>nil}],
          [:last_name, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"varchar(255)", :type=>:string, :ruby_default=>nil}]
        ]
        resource.stubs(:source_schema).returns(schema)

        resource.save
        assert_equal 3, resource.fields_dataset.count
      end

      def test_source_database
        resource = Factory(:resource)
        resource.connection.expects(:database)
        resource.source_database { puts "huge" }
      end

      def test_source_dataset
        resource = Factory.create(:resource)
        resource.source_dataset do |dataset|
          assert_kind_of Sequel::Dataset, dataset
          assert_equal "SELECT * FROM `people`", dataset.select_sql
        end
      end

      def test_source_schema
        resource = Factory.create(:resource)
        expected = [[:id, {:allow_null=>false, :default=>nil, :primary_key=>true, :db_type=>"int(11)", :type=>:integer, :ruby_default=>nil}], [:first_name, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"varchar(255)", :type=>:string, :ruby_default=>nil}], [:last_name, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"varchar(255)", :type=>:string, :ruby_default=>nil}]]
        assert_equal expected, resource.source_schema
      end

      def test_local_database
        db do |inf|
          databases = inf["SHOW DATABASES"].collect { |x| x[:Database] }
          inf.run("DROP DATABASE roflsauce")  if databases.include?("rolfsauce")
        end

        project = Factory(:project, :name => "roflsauce")
        resource = Factory(:resource, :name => "pants", :project => project)

        resource.local_database do |db|
          assert_kind_of Sequel::JDBC::Database, db
          assert db.test_connection
        end
      end

      def test_local_dataset
        db { |inf| inf.execute("DROP DATABASE IF EXISTS local_dataset_test") }

        project = Factory(:project, :name => "local_dataset test")
        resource = Factory(:resource, :name => "Resource 1", :project => project)
        field = resource.fields.first
        transformer = Factory(:transformer)
        transformation = Factory(:transformation, {
          :resource => resource, :transformer => transformer,
          :field => field
        })

        resource.local_dataset do |dataset|
          database = dataset.db
          assert_equal Config.connection_string("local_dataset_test", :create_database => true, :zero_date_time_behavior => :convert_to_null), database.uri
          assert_equal database[:resource_1].select_sql, dataset.select_sql
        end
      end

      def test_update_fields
        project = Factory(:project, :name => "local_dataset test")
        resource = Factory(:resource, :name => "Resource 1", :project => project)
        first_name = resource.fields_dataset[:name => 'first_name']
        last_name = resource.fields_dataset[:name => 'last_name']

        transformer_1 = Factory(:transformer, {
          :name => "strlen", :allowed_types => %w{string},
          :result_type => 'integer', :code => 'value.length'
        })
        transformation_1 = Factory(:transformation, {
          :resource => resource, :transformer => transformer_1,
          :field => first_name
        })
        transformer_2 = Factory(:transformer, {
          :name => "random", :allowed_types => %w{string},
          :result_type => 'integer', :code => 'rand(Time.now.to_i)'
        })
        transformation_2 = Factory(:transformation, {
          :resource => resource, :transformer => transformer_2,
          :field => last_name
        })
        #transformer_3 = Factory(:transformer, {
          #:name => "timeify", :allowed_types => %w{integer},
          #:result_type => 'datetime', :code => 'Time.at(value)'
        #})
        #transformation_3 = Factory(:transformation, {
          #:resource => resource, :transformer => transformer_3,
          #:field => last_name
        #})

        resource.update_fields

        first_name.refresh
        assert_equal 'int(11)', first_name.local_db_type
        assert_equal 'integer', first_name.local_type

        last_name.refresh
        assert_equal 'int(11)', last_name.local_db_type
        assert_equal 'integer', last_name.local_type
      end

      def test_transform
        database_count = Sequel::DATABASES.length

        project = Factory(:project, :name => "Awesome Test Project")
        resource = Factory(:resource, :name => "pants", :project => project)
        transformer = Factory(:transformer, :allowed_types => %w{string}, :code => 'value.downcase')
        transformation = Factory(:transformation, {
          :resource => resource, :transformer => transformer,
          :field => resource.fields_dataset[:name => 'first_name']
        })

        original_row = nil
        resource.source_dataset { |ds| original_row = ds.first }

        Timecop.freeze(Time.now) do
          resource.transform!
          assert_equal Time.now, resource.transformed_at
        end

        Sequel.connect(Config.connection_string("awesome_test_project")) do |db|
          assert db.tables.include?(:pants)

          expected = [[:id, {:allow_null=>false, :default=>nil, :primary_key=>true, :db_type=>"int(11)", :type=>:integer, :ruby_default=>nil}], [:first_name, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"varchar(255)", :type=>:string, :ruby_default=>nil}], [:last_name, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"varchar(255)", :type=>:string, :ruby_default=>nil}]]
          assert_equal expected, db.schema(:pants)

          changed_row = db[:pants][:id => original_row[:id]]
          assert_equal original_row[:first_name].downcase, changed_row[:first_name]
        end

        assert_equal "ok", resource.status
        assert_equal database_count, Sequel::DATABASES.length
      end

      def test_initial_status
        resource = Factory(:resource)
        assert_equal "ok", resource.status
      end

      def test_status_after_adding_first_transformation
        resource = Factory(:resource)
        transformation = Factory(:transformation, :resource => resource)
        assert_equal "out_of_date", resource.status
      end

      def test_status_when_transformed_at_is_old
        resource = Factory(:resource, :transformed_at => Time.now - 20)
        transformation = Factory(:transformation, :resource => resource)
        assert_equal "out_of_date", resource.status
      end

      def test_status_when_transformations_are_updated
        now = Time.now
        resource = Factory(:resource, :transformed_at => now - 1)
        transformation = Factory(:transformation, :resource => resource, :created_at => now - 2, :updated_at => now - 2)
        assert_equal "out_of_date", resource.status
      end

      def test_status_when_transformations_are_removed
        resource = Factory(:resource, :transformed_at => Time.now - 20)
        transformation = Factory(:transformation, :resource => resource)
        assert_equal "out_of_date", resource.status
        transformation.destroy
        assert_equal "ok", resource.status
      end

      def test_final_database_is_source_database_without_transformations
        resource = Factory(:resource)
        resource.source_database do |expected|
          resource.final_database do |actual|
            assert_equal expected.uri, actual.uri
          end
        end
      end

      def test_final_database_is_local_database_with_transformations
        resource = Factory(:resource)
        transformation = Factory(:transformation, :resource => resource)
        resource.local_database do |expected|
          resource.final_database do |actual|
            assert_equal expected.uri, actual.uri
          end
        end
      end

      def test_final_dataset_is_source_dataset_without_transformations
        resource = Factory(:resource)
        resource.source_dataset do |expected|
          resource.final_dataset do |actual|
            assert_equal expected.select_sql, actual.select_sql
          end
        end
      end

      def test_final_dataset_is_local_dataset_with_transformations
        resource = Factory(:resource)
        transformation = Factory(:transformation, :resource => resource)
        resource.local_dataset do |expected|
          resource.final_dataset do |actual|
            assert_equal expected.select_sql, actual.select_sql
          end
        end
      end

      def test_scenarios
        project = Factory(:project)
        resource = Factory(:resource, :project => project)
        scenario = Factory(:scenario, :project => project, :resource_1 => resource)
        assert_equal [scenario], resource.scenarios
      end

      def test_running_jobs
        resource = Factory(:resource)
        job = Factory(:resource_job, :resource => resource, :status => 'running')
        assert_equal [job], resource.running_jobs
      end

      def test_scheduled_jobs
        resource = Factory(:resource)
        job = Factory(:resource_job, :resource => resource)
        assert_equal [job], resource.scheduled_jobs
      end

      def test_source_dataset_selects_specified_columns
        resource = Factory(:resource)
        resource.fields_dataset.filter(["name NOT IN ?", %w{id first_name}]).update(:is_selected => false)
        resource.source_dataset do |ds|
          assert_equal [:id, :first_name], ds.columns

          # NOTE: in MySQL, when selecting strings (ex: SELECT 'foo'),
          # the name of the column in sequel is :foo instead of :"'foo'",
          # because of the way MySQL names columns
          assert_equal "SELECT `id`, `first_name` FROM `people`", ds.select_sql
        end
      end

      def test_transforming_only_gets_specified_columns
        resource = Factory(:resource)
        resource.fields_dataset.filter(["name NOT IN ?", %w{id first_name}]).update(:is_selected => false)
        transformer = Factory(:transformer)
        transformation = Factory(:transformation, {
          :resource => resource, :transformer => transformer,
          :field => resource.fields_dataset[:name => 'first_name']
        })
        resource.transform!
        resource.local_database do |db|
          schema = db.schema(resource.slug.to_sym)
          assert_equal [:id, :first_name], schema.collect(&:first)
        end
      end
    end
  end
end
