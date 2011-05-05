require 'helper'

module Coupler
  module Models
    class TestField < Coupler::Test::UnitTest
      def new_field(attrs = {})
        f = Field.new({
          :name => 'foo',
          :type => 'string',
          :db_type => 'varchar(255)',
          :is_primary_key => false,
          :is_selected => true,
          :resource => @resource
        }.merge(attrs))
      end

      def setup
        super
        @resource = stub("resource", :id => 123, :pk => 123, :associations => {})
      end

      test "sequel model" do
        assert_equal ::Sequel::Model, Field.superclass
        assert_equal :fields, Field.table_name
      end

      test "many to one resource" do
        assert_respond_to Field.new, :resource
      end

      test "one to many transformations" do
        assert_respond_to Field.new, :transformations
      end

      test "requires unique name across resources" do
        field = new_field
        field.expects(:validates_unique).with([:name, :resource_id])
        field.valid?
      end

      test "force selected on primary key fields" do
        field_1 = new_field(:name => 'field_1', :is_primary_key => false, :is_selected => false).save!
        assert !field_1.is_selected

        field_2 = new_field(:name => 'field_2', :is_primary_key => true, :is_selected => false).save!
        assert field_2.is_selected
      end

      test "original_column_options" do
        field = new_field({
          :local_type => 'integer',
          :local_db_type => 'int(11)',
        })
        assert_equal({
          :name => 'foo', :type => 'varchar(255)',
          :primary_key => false
        }, field.original_column_options)
      end

      test "local_column_options" do
        field_1 = new_field({
          :type => 'integer', :db_type => 'int(11)',
          :local_type => 'string', :local_db_type => 'varchar(255)',
          :is_primary_key => false
        })
        field_2 = new_field({
          :type => 'integer', :db_type => 'int(11)',
          :is_primary_key => false
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

      test "final_type and final_db_type uses local if exists" do
        field_1 = new_field({
          :name => 'foo', :type => 'integer', :db_type => 'int(11)',
          :local_type => 'string', :local_db_type => 'varchar(255)',
          :is_primary_key => false
        })
        field_2 = new_field({
          :name => 'foo', :type => 'integer', :db_type => 'int(11)',
          :local_type => nil, :local_db_type => nil,
          :is_primary_key => false
        })
        assert_equal 'string', field_1.final_type
        assert_equal 'varchar(255)', field_1.final_db_type
        assert_equal 'integer', field_2.final_type
        assert_equal 'int(11)', field_2.final_db_type
      end
    end
  end
end
