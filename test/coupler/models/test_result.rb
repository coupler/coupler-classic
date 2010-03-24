require File.dirname(__FILE__) + '/../../helper'

module Coupler
  module Models
    class TestResult < Test::Unit::TestCase
      def test_sequel_model
        assert_equal ::Sequel::Model, Result.superclass
        assert_equal :results, Result.table_name
      end

      def test_many_to_one_scenario
        assert_respond_to Result.new, :scenario
      end

      def test_sets_scenario_version
        scenario = Factory(:scenario)
        result = Result.create(:scenario => scenario)
        assert_equal scenario.version, result.scenario_version
      end
    end
  end
end
