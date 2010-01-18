require File.dirname(__FILE__) + '/../../helper'

module Coupler
  module Comparators
    class TestExact < ActiveSupport::TestCase
      def test_base_superclass
        assert_equal Base, Exact.superclass
      end

      def test_registers_itself
        assert Comparators.list.include?("exact")
      end

      def test_score_match
        comparator = Exact.new('field_name' => 'first_name')
        assert_equal 100, comparator.score({:first_name => "Harry"}, {:first_name => "Harry"})
      end

      def test_score_nonmatch
        comparator = Exact.new('field_name' => 'first_name')
        assert_equal 0, comparator.score({:first_name => "Harry"}, {:first_name => "Ron"})
      end

      def test_options
        expected = [
          {:label => "Field", :name => "field_name", :type => "text"}
        ]
        assert_equal expected, Exact::OPTIONS
      end
    end
  end
end
