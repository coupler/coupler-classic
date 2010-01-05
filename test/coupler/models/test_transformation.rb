require File.dirname(__FILE__) + '/../../helper'

module Coupler
  module Models
    class TestResource < ActiveSupport::TestCase
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

      def test_runs_update_status_on_resource_after_save
        resource = Factory(:resource)
        resource.expects(:update_status!)
        transformation = Factory(:transformation, :resource => resource)
      end

      def test_runs_update_status_on_resource_after_destroy
        # can't use mocks because the resource is re-initialized
        resource = Factory(:resource)
        transformation = Factory(:transformation, :resource => resource)
        assert_equal "out of date", resource.reload.status
        transformation.destroy
        assert_equal "ok", resource.reload.status
      end
    end
  end
end
