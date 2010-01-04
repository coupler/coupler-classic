require File.dirname(__FILE__) + '/../../helper'

module Coupler
  module Models
    class TestMatcher < ActiveSupport::TestCase
      def test_sequel_model
        assert_equal ::Sequel::Model, Matcher.superclass
        assert_equal :matchers, Matcher.table_name
      end

      def test_many_to_one_scenario
        assert_respond_to Matcher.new, :scenario
      end
    end
  end
end
