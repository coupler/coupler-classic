require File.dirname(__FILE__) + '/../../helper'

module Coupler
  module Models
    class TestResource < Test::Unit::TestCase
      def test_sequel_model
        assert_equal ::Sequel::Model, Transformation.superclass
        assert_equal :transformations, Transformation.table_name
      end

      def test_many_to_one_resources
        assert_respond_to Transformation.new, :resource
      end

      def test_requires_resource_id
        transformation = Factory.build(:transformation, :resource => nil)
        assert !transformation.valid?
      end

      def test_requires_transformer_id
        transformation = Factory.build(:transformation, :transformer => nil)
        assert !transformation.valid?
      end

      def test_requires_correct_field_type
        transformer = Factory(:transformer, :allowed_types => %w{integer})
        transformation = Factory.build(:transformation, :transformer => transformer, :field_name => 'first_name')
        assert !transformation.valid?
      end

      def test_requires_existing_field
        transformation = Factory.build(:transformation, :field_name => 'hagis')
        assert !transformation.valid?
      end

      def test_transform
        transformer = Factory(:transformer)
        transformation = Factory(:transformation, :transformer => transformer)

        data = {:id => 1, :first_name => "Peter"}
        expected = stub("result")
        transformation.transformer.expects(:transform).with(data, { :in => :first_name, :out => :first_name }).returns(expected)

        assert_equal expected, transformation.transform(data)
      end

      def test_new_schema
        transformer = Factory(:transformer)
        transformation = Factory(:transformation, :transformer => transformer, :field_name => 'first_name')

        original_schema = stub('original schema')
        new_schema = stub('new schema')
        transformation.transformer.expects(:new_schema).with(original_schema, 'first_name').returns(new_schema)
        assert_equal new_schema, transformation.new_schema(original_schema)
      end
    end
  end
end
