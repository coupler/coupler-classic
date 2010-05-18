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

      def test_requires_comparator_name
        matcher = Factory.build(:matcher, :comparator_name => nil)
        assert !matcher.valid?

        matcher.comparator_name = ""
        assert !matcher.valid?
      end

      def test_requires_valid_comparator_name
        matcher = Factory.build(:matcher, :comparator_name => "rofl")
        assert !matcher.valid?
      end

      def test_nested_attributes_for_comparisons
        project = Factory(:project)
        resource = Factory(:resource, :project => project)
        fields = resource.fields
        scenario = Factory(:scenario, :project => project, :resource_1_id => resource.id)
        matcher = Factory(:matcher, {
          :scenario => scenario,
          :comparisons_attributes => {
            '1' => {'field_1_id' => fields[1].id.to_s},
            '2' => {'field_1_id' => fields[2].id.to_s}
          }
        })
        assert_equal 2, matcher.comparisons_dataset.count
      end

      def test_rejects_empty_nested_attributes_for_comparisons
        project = Factory(:project)
        resource = Factory(:resource, :project => project)
        fields = resource.fields
        scenario = Factory(:scenario, :project => project, :resource_1_id => resource.id)
        matcher = Factory(:matcher, {
          :scenario => scenario,
          :comparisons_attributes => {
            '1' => {'field_1_id' => fields[1].id.to_s},
            '2' => {'field_1_id' => ''}
          }
        })
        assert_equal 1, matcher.comparisons_dataset.count
      end

      def test_deletes_comparisons_via_nested_attributes
        project = Factory(:project)
        resource = Factory(:resource, :project => project)
        fields = resource.fields
        scenario = Factory(:scenario, :project => project, :resource_1_id => resource.id)
        matcher = Factory(:matcher, {
          :scenario => scenario,
          :comparisons_attributes => {
            '1' => {'field_1_id' => fields[1].id.to_s, 'field_2_id' => fields[1].id.to_s},
            '2' => {'field_1_id' => fields[2].id.to_s, 'field_2_id' => fields[2].id.to_s},
          }
        })

        count = Comparison.count
        comparison = matcher.comparisons_dataset.first
        matcher.set({
          :updated_at => Time.now,
          :comparisons_attributes => [{:id => comparison.id, :_delete => true}]
        })
        matcher.save
        assert_equal 1, matcher.comparisons_dataset.count
        assert_equal count - 1, Comparison.count
      end
    end
  end
end
