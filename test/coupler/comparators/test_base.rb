require File.dirname(__FILE__) + '/../../helper'

module Coupler
  module Comparators
    class TestBase < Test::Unit::TestCase
      def setup
        super
        @comparator = Base.new({})
      end

      def test_score_raises_not_implemented_error
        assert_raises(NotImplementedError) do
          @comparator.score({}, {})
        end
      end
    end
  end
end
