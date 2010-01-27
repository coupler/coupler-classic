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
        transformation = Factory.build(:transformation, :resource => nil, :resource_id => nil)
        assert !transformation.valid?
      end
    end
  end
end
