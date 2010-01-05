require File.dirname(__FILE__) + '/../../helper'

module Coupler
  module Comparators
    class TestExact < ActiveSupport::TestCase
      def setup
        @comparator = Exact.new
      end

      def test_subclass_of_base
        assert_equal Base, Exact.superclass
      end

      def test_registration
        assert Comparators.list.include?("exact")
      end

      #def test_score
        #dataset = stub("dataset")
        #dataset.expects(:filter).with("t1.first_name = t2.first_name AND t1.id > t2.id")
        #comp = Exact.new(:field => "first_name")
        #comp.score(dataset)
      #end
    end
  end
end
