require File.dirname(__FILE__) + '/../../helper'

module Coupler
  module Comparators
    class TestBase < Test::Unit::TestCase
      def setup
        super
        @comparator = Base.new({'key' => ['id'], 'field_name' => 'foo'})
      end

      def test_simple_score_raises_not_implemented_error
        assert_raises(NotImplementedError) do
          @comparator.simple_score({}, {})
        end
      end

      def test_score_raises_not_implemented_error
        assert_raises(NotImplementedError) do
          @comparator.score(nil)
        end
      end

      def test_simple_scoring_method
        klass = Class.new(Base)
        klass.class_eval do
          def simple_score(first, second)
            100
          end
        end
        assert_equal :simple_score, klass.scoring_method
      end

      def test_normal_scoring_method
        klass = Class.new(Base)
        klass.class_eval do
          def score(dataset)
            100
          end
        end
        assert_equal :score, klass.scoring_method
      end

      def test_default_field_arity
        assert_equal 1, Base.field_arity
      end

      def test_checks_arity
        klass = Class.new(Base)
        def klass.field_arity; 2; end
        assert_raise(RuntimeError) do
          klass.new({'key' => 'id', 'field_name' => 'foo'})
        end
      end
    end
  end
end
