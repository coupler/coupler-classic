require File.dirname(__FILE__) + '/../../helper'

module Coupler
  module Models
    class TestScenario < ActiveSupport::TestCase
      def test_sequel_model
        assert_equal ::Sequel::Model, Scenario.superclass
        assert_equal :scenarios, Scenario.table_name
      end

      def test_many_to_one_project
        assert_respond_to Scenario.new, :project
      end

      def test_many_to_many_resources
        assert_respond_to Scenario.new, :resources
        resource = Factory(:resource)
        scenario = Factory(:scenario)
        resource.add_scenario(scenario)
        assert_equal [resource], scenario.resources
      end

      def test_one_to_many_matchers
        assert_respond_to Scenario.new, :matchers
      end
    end
  end
end
