require File.dirname(__FILE__) + '/../../helper'

module Coupler
  module Models
    class TestField < Test::Unit::TestCase
      def test_sequel_model
        assert_equal ::Sequel::Model, Field.superclass
        assert_equal :fields, Field.table_name
      end

      def test_many_to_one_resource
        assert_respond_to Field.new, :resource
      end

      def test_one_to_many_transformations
        assert_respond_to Field.new, :transformations
      end

      def test_requires_unique_name_across_resources
        resource_1 = Factory(:resource)
        resource_2 = Factory(:resource)

        field_1 = Factory(:field, :name => 'foobar', :resource => resource_1)
        field_2 = Factory.build(:field, :name => 'foobar', :resource => resource_1)
        assert !field_2.valid?

        field_3 = Factory.build(:field, :name => 'foobar', :resource => resource_2)
        assert field_3.valid?, field_3.errors.full_messages.join("; ")
      end

      def test_force_selected_on_primary_key_fields
        field = Factory(:field, :is_primary_key => 0, :is_selected => 0)
        assert !field.is_selected

        field = Factory(:field, :is_primary_key => 1, :is_selected => 0)
        assert field.is_selected
      end

      def test_original_column_options
        field = Factory(:field, {
          :name => 'foo', :type => 'integer', :db_type => 'int(11)',
          :local_type => 'string', :local_db_type => 'varchar(255)',
          :is_primary_key => 0
        })
        assert_equal({
          :name => 'foo', :type => 'int(11)',
          :primary_key => false
        }, field.original_column_options)
      end

      def test_local_column_options
        field_1 = Factory(:field, {
          :name => 'foo', :type => 'integer', :db_type => 'int(11)',
          :local_type => 'string', :local_db_type => 'varchar(255)',
          :is_primary_key => 0
        })
        field_2 = Factory(:field, {
          :name => 'foo', :type => 'integer', :db_type => 'int(11)',
          :is_primary_key => 0
        })

        assert_equal({
          :name => 'foo', :type => 'varchar(255)',
          :primary_key => false
        }, field_1.local_column_options)
        assert_equal({
          :name => 'foo', :type => 'int(11)',
          :primary_key => false
        }, field_2.local_column_options)
      end

      def test_final_type_and_final_db_type_uses_local_if_exists
        field_1 = Factory(:field, {
          :name => 'foo', :type => 'integer', :db_type => 'int(11)',
          :local_type => 'string', :local_db_type => 'varchar(255)',
          :is_primary_key => 0
        })
        field_2 = Factory(:field, {
          :name => 'foo', :type => 'integer', :db_type => 'int(11)',
          :local_type => nil, :local_db_type => nil,
          :is_primary_key => 0
        })
        assert_equal 'string', field_1.final_type
        assert_equal 'varchar(255)', field_1.final_db_type
        assert_equal 'integer', field_2.final_type
        assert_equal 'int(11)', field_2.final_db_type
      end

      def test_scenarios_dataset
        project = Factory(:project)
        resource = Factory(:resource, :project => project)
        first_name = resource.fields_dataset[:name => 'first_name']
        scenario = Factory(:scenario, :resource_1 => resource, :project => project)
        matcher = Factory(:matcher,
          :comparisons_attributes => [
            {:lhs_type => 'field', :raw_lhs_value => first_name.id, :lhs_which => 1, :rhs_type => 'field', :raw_rhs_value => first_name.id, :rhs_which => 2, :operator => 'equals'},
          ],
          :scenario => scenario)
        ds = first_name.scenarios_dataset
        assert_equal scenario.id, ds.get(:id)
      end
    end
  end
end
