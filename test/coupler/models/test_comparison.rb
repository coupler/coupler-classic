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

      def test_serializes_lhs_and_rhs_values
        comparison = Factory(:comparison, {
          :lhs_type => "integer", :lhs_value => 123,
          :rhs_type => "integer", :rhs_value => 123
        })
        obj = Comparison[:id => comparison.id]
        assert_equal 123, obj.lhs_value
        assert_equal 123, obj.rhs_value
      end

      def test_requires_types_and_values
        comparison = Factory.build(:comparison, {
          :lhs_type => nil, :lhs_value => nil,
          :rhs_type => nil, :rhs_value => nil
        })
        assert !comparison.valid?
        [:lhs_type, :rhs_type, :lhs_value, :rhs_value].each do |attr|
          assert_not_nil comparison.errors.on(attr)
        end
      end

      def test_requires_valid_types
        comparison = Factory.build(:comparison, :lhs_type => 'foo', :rhs_type => 'foo')
        assert !comparison.valid?
        assert_not_nil comparison.errors.on(:lhs_type)
        assert_not_nil comparison.errors.on(:rhs_type)
      end

      def test_allows_valid_types
        comparison = Factory.build(:comparison, {
          :lhs_type => nil, :rhs_type => nil,
          :lhs_value => "123", :rhs_value => "123"
        })
        %w{field integer string}.each do |type|
          comparison.lhs_type = comparison.rhs_type = type
          assert comparison.valid?, comparison.errors.full_messages.join("; ")
        end
      end

      def test_requires_valid_operator
        comparison = Factory.build(:comparison, :operator => 'foo')
        assert !comparison.valid?
        assert_not_nil comparison.errors.on(:operator)
      end

      def test_allows_valid_operators
        comparison = Factory.build(:comparison, :operator => nil)
        %w{equals}.each do |op|
          comparison.operator = op
          assert comparison.valid?
        end
      end

      def test_value_methods_return_fields_if_type_is_field
        resource = Factory(:resource)
        field_1 = resource.fields[0]
        field_2 = resource.fields[1]
        comparison = Factory(:comparison, {
          :lhs_type => "field", :lhs_value => field_1.id,
          :rhs_type => "field", :rhs_value => field_2.id
        })
        obj = Comparison[:id => comparison.id]
        assert_equal field_1, obj.lhs_value
        assert_equal field_2, obj.rhs_value
      end

      def test_values_are_coerced_to_integer_when_type_is_integer
        comparison = Factory(:comparison, {
          :lhs_type => "integer", :lhs_value => "123",
          :rhs_type => "integer", :rhs_value => "123"
        })
        obj = Comparison[:id => comparison.id]
        assert_equal 123, obj.lhs_value
        assert_equal 123, obj.rhs_value
      end

      def test_fields_returns_lhs_field
        resource = Factory(:resource)
        field = resource.fields[0]
        comparison = Factory(:comparison, {
          :lhs_type => "field", :lhs_value => field.id,
          :rhs_type => "integer", :rhs_value => 123
        })
        assert_equal [field], comparison.fields
      end

      def test_fields_returns_rhs_field
        resource = Factory(:resource)
        field = resource.fields[0]
        comparison = Factory(:comparison, {
          :lhs_type => "integer", :lhs_value => 123,
          :rhs_type => "field", :rhs_value => field.id,
        })
        assert_equal [field], comparison.fields
      end

      def test_fields_returns_two_fields
        resource = Factory(:resource)
        field_1 = resource.fields[0]
        field_2 = resource.fields[1]
        comparison = Factory(:comparison, {
          :lhs_type => "field", :lhs_value => field_1.id,
          :rhs_type => "field", :rhs_value => field_2.id,
        })
        assert_equal [field_1, field_2], comparison.fields
      end

      def test_fields_returns_one_field_if_both_are_equal
        resource = Factory(:resource)
        field = resource.fields[0]
        comparison = Factory(:comparison, {
          :lhs_type => "field", :lhs_value => field.id,
          :rhs_type => "field", :rhs_value => field.id,
        })
        assert_equal [field], comparison.fields
      end

      def test_fields_returns_empty_array
        comparison = Factory(:comparison, {
          :lhs_type => "integer", :lhs_value => 123,
          :rhs_type => "integer", :rhs_value => 123,
        })
        assert_equal [], comparison.fields
      end
    end
  end
end
