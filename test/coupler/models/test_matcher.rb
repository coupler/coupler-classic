require File.dirname(__FILE__) + '/../../helper'

module Coupler
  module Models
    class TestMatcher < Test::Unit::TestCase
      def test_sequel_model
        assert_equal ::Sequel::Model, Matcher.superclass
        assert_equal :matchers, Matcher.table_name
      end

      def test_many_to_one_scenario
        assert_respond_to Matcher.new, :scenario
      end

      def test_requires_comparator_name
        matcher = Factory.build(:matcher, :comparator_name => nil)
        assert !matcher.valid?

        matcher.comparator_name = ""
        assert !matcher.valid?
      end

      def test_requires_valid_comparator_name
        matcher = Factory.build(:matcher, :comparator_name => "rofl")
        assert !matcher.valid?
      end

      def test_serializes_comparator_options
        expected = {:test => 123}
        matcher = Factory(:matcher, :comparator_options => expected)
        assert_equal expected, Matcher[:id => matcher.id].comparator_options
      end
    end
  end
end
