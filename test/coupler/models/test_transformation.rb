require File.dirname(__FILE__) + '/../../helper'

module Coupler
  module Models
    class TestResource < Test::Unit::TestCase
      def test_sequel_model
        assert_equal ::Sequel::Model, Transformation.superclass
        assert_equal :transformations, Transformation.table_name
      end

      def test_many_to_one_resource
        assert_respond_to Transformation.new, :resource
      end

      def test_many_to_one_field
        assert_respond_to Transformation.new, :source_field
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
        resource = Factory(:resource)
        field = resource.fields_dataset.first
        transformation = Factory.build(:transformation, :transformer => transformer, :source_field => field)
        assert !transformation.valid?
      end

      def test_requires_existing_field
        transformation = Factory.build(:transformation, :source_field => nil, :source_field_id => 1337)
        assert !transformation.valid?
      end

      def test_transform
        transformer = Factory(:transformer)
        resource = Factory(:resource)
        transformation = Factory(:transformation, {
          :transformer => transformer,
          :resource => resource,
          :source_field => resource.fields_dataset[:name => 'first_name']
        })

        data = {:id => 1, :first_name => "Peter"}
        expected = stub("result")
        transformation.transformer.expects(:transform).with(data, { :in => :first_name, :out => :first_name }).returns(expected)

        assert_equal expected, transformation.transform(data)
      end

      def test_field_changes
        transformer = Factory(:transformer)
        resource = Factory(:resource)
        field = resource.fields_dataset.first
        transformation = Factory(:transformation, {
          :transformer => transformer, :resource => resource,
          :source_field => field
        })

        result = stub('result')
        transformation.transformer.expects(:field_changes).with(transformation.source_field).returns(result)
        assert_equal result, transformation.field_changes
      end

      def test_updates_resource_fields_on_save
        transformer = Factory.build(:transformer)
        resource = Factory.build(:resource)
        Timecop.freeze(Time.now - 1000) do
          transformer.save
          resource.save
        end
        field = resource.fields_dataset.first
        time = field.updated_at
        transformation = Factory(:transformation, :resource => resource, :transformer => transformer, :source_field => field)
        field.refresh
        assert field.updated_at > time, "#{field.updated_at} isn't more recent than #{time}"
      end
    end
  end
end
