require File.dirname(__FILE__) + '/../../helper'

module Coupler
  module Models
    class TestResult < Test::Unit::TestCase
      def test_sequel_model
        assert_equal ::Sequel::Model, Result.superclass
        assert_equal :results, Result.table_name
      end
    end
  end
end
