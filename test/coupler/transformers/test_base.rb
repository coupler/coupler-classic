require File.dirname(__FILE__) + '/../../helper'

module Coupler
  module Transformers
    class TestBase < Test::Unit::TestCase
      def setup
        super
        @transformer = Base.new({})
      end

      def test_transform_raises_not_implemented_error
        assert_raises(NotImplementedError) do
          @transformer.transform({})
        end
      end

      def test_schema_returns_schema_unchanged
        assert_equal ['foo', 'bar'], @transformer.schema(['foo', 'bar'])
      end
    end
  end
end
