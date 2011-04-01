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
        scenario = Factory(:scenario, :project => project, :resource_1 => resource)
        matcher = Factory(:matcher, {
          :scenario => scenario,
          :comparisons_attributes => {
            '1' => {
              'lhs_type' => 'field', 'raw_lhs_value' => fields[1].id.to_s,
              'rhs_type' => 'field', 'raw_rhs_value' => fields[2].id.to_s,
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
              'lhs_type' => 'integer', 'raw_lhs_value' => 1,
              'rhs_type' => 'integer', 'raw_rhs_value' => 1,
              'operator' => 'foo'
            }
          }
        })
        assert !matcher.valid?
      end

      def test_deletes_comparisons_via_nested_attributes
        project = Factory(:project)
        resource = Factory(:resource, :project => project)
        fields = resource.fields
        scenario = Factory(:scenario, :project => project, :resource_1 => resource)
        matcher = Factory(:matcher, {
          :scenario => scenario,
          :comparisons_attributes => {
            '1' => {
              'lhs_type' => 'field', 'raw_lhs_value' => fields[1].id.to_s,
              'rhs_type' => 'field', 'raw_rhs_value' => fields[2].id.to_s,
              'operator' => 'equals'
            },
            '2' => {
              'lhs_type' => 'integer', 'raw_lhs_value' => 1,
              'rhs_type' => 'integer', 'raw_rhs_value' => 1,
              'operator' => 'equals'
            }
          }
        })
        assert_equal 2, matcher.comparisons_dataset.count

        comparison = matcher.comparisons_dataset.first
        matcher.update({
          :updated_at => Time.now,
          :comparisons_attributes => [{:id => comparison.id, :_delete => true}]
        })
        assert_equal 1, matcher.comparisons_dataset.count
      end

      def test_requires_at_least_one_field_to_field_comparison
        matcher = Factory.build(:matcher, {
          :comparisons_attributes => {
            '1' => {
              'lhs_type' => 'integer', 'raw_lhs_value' => 1,
              'rhs_type' => 'integer', 'raw_rhs_value' => 1,
              'operator' => 'equals'
            }
          }
        })
        assert !matcher.valid?
      end

      def test_cross_match_is_true_when_a_comparison_is_a_cross_match
        resource = Factory(:resource)
        scenario = Factory(:scenario, :project => resource.project, :resource_1 => resource)
        matcher = Factory(:matcher, {
          :scenario => scenario,
          :comparisons_attributes => {
            '1' => {
              'lhs_type' => 'field', 'raw_lhs_value' => resource.fields_dataset[:name => 'first_name'].id,
              'rhs_type' => 'field', 'raw_rhs_value' => resource.fields_dataset[:name => 'last_name'].id,
              'operator' => 'equals'
            }
          }
        })
        assert matcher.cross_match?
      end
    end
  end
end
