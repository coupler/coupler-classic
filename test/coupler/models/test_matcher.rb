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

      def test_one_to_many_comparisons
        assert_respond_to Matcher.new, :comparisons
      end

      def test_nested_attributes_for_comparisons
        project = Factory(:project)
        resource = Factory(:resource, :project => project)
        fields = resource.fields
        scenario = Factory(:scenario, :project => project, :resource_1_id => resource.id)
        matcher = Factory(:matcher, {
          :scenario => scenario,
          :comparisons_attributes => {
            '1' => {
              'lhs_type' => 'field', 'lhs_value' => fields[1].id.to_s,
              'rhs_type' => 'field', 'rhs_value' => fields[2].id.to_s,
              'operator' => 'equals'
            }
          }
        })
        assert_equal 1, matcher.comparisons_dataset.count
      end

      def test_invalid_if_comparisons_are_invalid
        matcher = Factory.build(:matcher, {
          :comparisons_attributes => {
            '1' => {
              'lhs_type' => 'integer', 'lhs_value' => 1,
              'rhs_type' => 'integer', 'rhs_value' => 1,
              'operator' => 'foo'
            }
          }
        })
        assert !matcher.valid?
      end

      def test_deletes_comparisons_via_nested_attributes
        matcher = Factory(:matcher, {
          :comparisons_attributes => {
            '1' => {
              'lhs_type' => 'integer', 'lhs_value' => 1,
              'rhs_type' => 'integer', 'rhs_value' => 1,
              'operator' => 'equals'
            }
          }
        })
        assert_equal 1, matcher.comparisons_dataset.count

        comparison = matcher.comparisons_dataset.first
        matcher.update({
          :updated_at => Time.now,
          :comparisons_attributes => [{:id => comparison.id, :_delete => true}]
        })
        assert_equal 0, matcher.comparisons_dataset.count
      end
    end
  end
end
