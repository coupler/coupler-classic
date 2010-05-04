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
    end
  end
end
