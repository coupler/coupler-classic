require File.dirname(__FILE__) + '/../../helper'

module Coupler
  module Models
    class TestComparison < Test::Unit::TestCase
      def test_sequel_model
        assert_equal ::Sequel::Model, Comparison.superclass
        assert_equal :comparisons, Comparison.table_name
      end

      def test_many_to_one_matcher
        assert_respond_to Comparison.new, :matcher
      end

      def test_many_to_one_field_1
        assert_respond_to Comparison.new, :field_1
      end

      def test_many_to_one_field_2
        assert_respond_to Comparison.new, :field_2
      end
    end
  end
end
