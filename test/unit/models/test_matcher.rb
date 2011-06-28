require 'helper'

module CouplerUnitTests
  module ModelTests
    class TestMatcher < Coupler::Test::UnitTest
      def new_matcher(attribs = {})
        values = {
          :scenario => @scenario,
          :comparisons_attributes => [{
            :lhs_type => 'field', :raw_lhs_value => 1,
            :rhs_type => 'field', :raw_rhs_value => 2,
            :operator => 'equals'
          }]
        }.update(attribs)
        m = Matcher.new(values)
        m.stubs(:scenario_dataset).returns(stub({:all => [values[:scenario]]}))
        m
      end

      def setup
        super
        @scenario = stub('scenario', :pk => 456, :id => 456, :associations => {})
        @field_1 = stub('field 1', :pk => 1, :id => 1, :associations => {})
        @field_2 = stub('field 2', :pk => 2, :id => 2, :associations => {})
      end

      test "sequel model" do
        assert_equal ::Sequel::Model, Matcher.superclass
        assert_equal :matchers, Matcher.table_name
      end

      test "many to one scenario" do
        assert_respond_to Matcher.new, :scenario
      end

      test "one to many comparisons" do
        assert_respond_to Matcher.new, :comparisons
      end

      test "nested attributes for comparisons" do
        assert_respond_to Matcher.new, :comparisons_attributes=
      end

      #test "deletes comparisons via nested attributes" do
        #matcher = new_matcher({
          #:comparisons_attributes => [
            #{
              #'lhs_type' => 'field', 'raw_lhs_value' => fields[1].id.to_s,
              #'rhs_type' => 'field', 'raw_rhs_value' => fields[2].id.to_s,
              #'operator' => 'equals'
            #},
            #{
              #'lhs_type' => 'integer', 'raw_lhs_value' => 1,
              #'rhs_type' => 'integer', 'raw_rhs_value' => 1,
              #'operator' => 'equals'
            #}
          #]
        #})
        #assert_equal 2, matcher.comparisons_dataset.count

        #comparison = matcher.comparisons_dataset.first
        #matcher.update({
          #:updated_at => Time.now,
          #:comparisons_attributes => [{:id => comparison.id, :_delete => true}]
        #})
        #assert_equal 1, matcher.comparisons_dataset.count
      #end

      test "requires at least one field to field comparison" do
        matcher = new_matcher
        matcher.expects(:comparisons).returns([stub(:rhs_type => "integer", :lhs_type => "integer")])
        assert !matcher.valid?
      end

      test "cross_match is true when a comparison is a cross match" do
        matcher = new_matcher
        matcher.expects(:comparisons).returns([mock(:cross_match? => true)])
        assert matcher.cross_match?
      end
    end
  end
end
