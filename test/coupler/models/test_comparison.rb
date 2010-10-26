require File.dirname(__FILE__) + '/../../helper'

module Coupler
  module Models
    class TestComparison < Test::Unit::TestCase
      def sequel_expr(*args)
        if args.length == 1
          obj = args[0]
          obj.is_a?(Sequel::SQL::BooleanExpression) ? obj : Sequel::SQL::BooleanExpression.from_value_pairs(obj)
        else
          Sequel::SQL::BooleanExpression.new(*args)
        end
      end

      def setup
        super
        @resource = Factory(:resource)
      end

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
        %w{equals does_not_equal greater_than less_than}.each do |op|
          comparison.operator = op
          assert comparison.valid?
        end
      end

      def test_requires_valid_lhs_which
        field = @resource.fields_dataset[:name => 'first_name']
        comparison = Factory.build(:comparison, :lhs_value => field, :lhs_type => 'field', :lhs_which => 123)
        assert !comparison.valid?
      end

      def test_requires_valid_rhs_which
        field = @resource.fields_dataset[:name => 'first_name']
        comparison = Factory.build(:comparison, :rhs_value => field, :rhs_type => 'field', :rhs_which => 123)
        assert !comparison.valid?
      end

      def test_value_methods_return_fields_if_type_is_field
        field_1 = @resource.fields_dataset[:name => 'first_name']
        field_2 = @resource.fields_dataset[:name => 'last_name']
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
        field = @resource.fields[0]
        comparison = Factory(:comparison, {
          :lhs_type => "field", :lhs_value => field.id,
          :rhs_type => "integer", :rhs_value => 123
        })
        assert_equal [field], comparison.fields
      end

      def test_fields_returns_rhs_field
        field = @resource.fields[0]
        comparison = Factory(:comparison, {
          :lhs_type => "integer", :lhs_value => 123,
          :rhs_type => "field", :rhs_value => field.id,
        })
        assert_equal [field], comparison.fields
      end

      def test_fields_returns_two_fields
        field_1 = @resource.fields_dataset[:name => 'first_name']
        field_2 = @resource.fields_dataset[:name => 'last_name']
        comparison = Factory(:comparison, {
          :lhs_type => "field", :lhs_value => field_1.id,
          :rhs_type => "field", :rhs_value => field_2.id,
        })
        assert_equal [field_1, field_2], comparison.fields
      end

      def test_fields_returns_empty_array
        comparison = Factory(:comparison, {
          :lhs_type => "integer", :lhs_value => 123,
          :rhs_type => "integer", :rhs_value => 123,
        })
        assert_equal [], comparison.fields
      end

      def test_operator_symbol
        comparison = Comparison.new(:operator => 'equals')
        assert_equal "=", comparison.operator_symbol
        comparison.operator = "does_not_equal"
        assert_equal "!=", comparison.operator_symbol
        comparison.operator = "greater_than"
        assert_equal ">", comparison.operator_symbol
        comparison.operator = "less_than"
        assert_equal "<", comparison.operator_symbol
      end

      %w{lhs rhs}.each do |name|
        # A mite silly, this is.
        define_method(:"test_#{name}_label") do
          field = @resource.fields[0]
          comparison = Comparison.new(:"#{name}_type" => 'field', :"#{name}_value" => field.id)
          assert_equal "#{field.name} (#{@resource.name})", comparison.send("#{name}_label")

          comparison.send("#{name}_which=", 1)
          assert_equal %{#{field.name} (#{@resource.name}<span class="sup">1</span>)}, comparison.send("#{name}_label")

          comparison.send("#{name}_which=", 2)
          assert_equal %{#{field.name} (#{@resource.name}<span class="sup">2</span>)}, comparison.send("#{name}_label")

          comparison.send("#{name}_type=", 'integer')
          comparison.send("#{name}_value=", 123)
          assert_equal "123", comparison.send("#{name}_label")

          comparison.send("#{name}_type=", 'string')
          comparison.send("#{name}_value=", 'foo')
          assert_equal %{"foo"}, comparison.send("#{name}_label")
        end
      end

      def test_apply_field_equality
        field = @resource.fields_dataset[:name => 'first_name']
        comparison = Factory(:comparison, {
          :lhs_type => 'field', :lhs_value => field.id, :lhs_which => 1,
          :rhs_type => 'field', :rhs_value => field.id, :rhs_which => 2,
          :operator => 'equals'
        })
        dataset = mock('dataset', :opts => {})
        dataset.expects(:clone).with({:select => [:first_name], :order => [:first_name]}).returns(dataset)
        dataset.expects(:filter).with(~{:first_name => nil}).returns(dataset)
        assert_equal dataset, comparison.apply(dataset)
      end

      def test_apply_field_equality_to_one_side_only
        field = @resource.fields_dataset[:name => 'first_name']
        comparison = Factory(:comparison, {
          :lhs_type => 'field', :lhs_value => field.id, :lhs_which => 1,
          :rhs_type => 'field', :rhs_value => field.id, :rhs_which => 2,
          :operator => 'equals'
        })
        dataset_1 = mock('dataset', :opts => {})
        dataset_1.expects(:clone).with({:select => [:first_name], :order => [:first_name]}).returns(dataset_1)
        dataset_1.expects(:filter).with(~{:first_name => nil}).returns(dataset_1)
        dataset_2 = mock('dataset', :opts => {})
        dataset_2.expects(:clone).with({:select => [:first_name], :order => [:first_name]}).returns(dataset_2)
        dataset_2.expects(:filter).with(~{:first_name => nil}).returns(dataset_2)

        assert_equal dataset_1, comparison.apply(dataset_1, 0)
        assert_equal dataset_2, comparison.apply(dataset_2, 1)
      end

      def test_apply_two_field_equality
        field_1 = @resource.fields_dataset[:name => 'first_name']
        field_2 = @resource.fields_dataset[:name => 'last_name']
        comparison = Factory(:comparison, {
          :lhs_type => 'field', :lhs_value => field_1.id, :lhs_which => 1,
          :rhs_type => 'field', :rhs_value => field_2.id, :rhs_which => 2,
          :operator => 'equals'
        })
        dataset = mock('dataset', :opts => {})
        dataset.expects(:clone).with({:select => [:first_name, :last_name], :order => [:first_name, :last_name]}).returns(dataset)
        dataset.expects(:filter).with(~{:first_name => nil}, ~{:last_name => nil}).returns(dataset)
        assert_equal dataset, comparison.apply(dataset)
      end

      def test_apply_two_field_equality_to_one_side_only
        field_1 = @resource.fields_dataset[:name => 'first_name']
        field_2 = @resource.fields_dataset[:name => 'last_name']
        comparison = Factory(:comparison, {
          :lhs_type => 'field', :lhs_value => field_1.id, :lhs_which => 1,
          :rhs_type => 'field', :rhs_value => field_2.id, :rhs_which => 2,
          :operator => 'equals'
        })
        dataset_1 = mock('dataset', :opts => {})
        dataset_1.expects(:clone).with({:select => [:first_name], :order => [:first_name]}).returns(dataset_1)
        dataset_1.expects(:filter).with(~{:first_name => nil}).returns(dataset_1)
        dataset_2 = mock('dataset', :opts => {})
        dataset_2.expects(:clone).with({:select => [:last_name], :order => [:last_name]}).returns(dataset_2)
        dataset_2.expects(:filter).with(~{:last_name => nil}).returns(dataset_2)

        assert_equal dataset_1, comparison.apply(dataset_1, 0)
        assert_equal dataset_2, comparison.apply(dataset_2, 1)
      end

=begin
      def test_apply_field_inequality_to_single_dataset
        field = @resource.fields_dataset[:name => 'first_name']
        comparison = Factory(:comparison, {
          :lhs_type => 'field', :lhs_value => field.id, :lhs_which => 1,
          :rhs_type => 'field', :rhs_value => field.id, :rhs_which => 2,
          :operator => 'does_not_equal'
        })
        dataset = mock('dataset', :opts => {})
        dataset.expects(:clone).with({:select => [:first_name], :order => [:first_name]}).returns(dataset)
        dataset.expects(:filter).with(~{:first_name => nil}).returns(dataset)
        assert_equal dataset, comparison.apply(dataset)
      end

      def test_apply_field_inequality_to_dual_datasets
        field = @resource.fields_dataset[:name => 'first_name']
        comparison = Factory(:comparison, {
          :lhs_type => 'field', :lhs_value => field.id, :lhs_which => 1,
          :rhs_type => 'field', :rhs_value => field.id, :rhs_which => 2,
          :operator => 'does_not_equal'
        })
        dataset_1 = mock('dataset_1', :opts => {})
        dataset_1.expects(:clone).with({:select => [:first_name], :order => [:first_name]}).returns(dataset_1)
        dataset_1.expects(:filter).with(~{:first_name => nil}).returns(dataset_1)
        dataset_2 = mock('dataset_2', :opts => {})
        dataset_2.expects(:clone).with({:select => [:first_name], :order => [:first_name]}).returns(dataset_2)
        dataset_2.expects(:filter).with(~{:first_name => nil}).returns(dataset_2)
        assert_equal [dataset_1, dataset_2], comparison.apply(dataset_1, dataset_2)
      end
=end

      def test_apply_same_row_field_equality_indifferently
        # Obviously these comparisons don't really make any sense IRL
        field_1 = @resource.fields_dataset[:name => 'first_name']
        field_2 = @resource.fields_dataset[:name => 'last_name']
        comparison_1 = Factory(:comparison, {
          :lhs_type => 'field', :lhs_value => field_1.id, :lhs_which => 1,
          :rhs_type => 'field', :rhs_value => field_2.id, :rhs_which => 1,
          :operator => 'equals'
        })
        comparison_2 = Factory(:comparison, {
          :lhs_type => 'field', :lhs_value => field_2.id, :lhs_which => 2,
          :rhs_type => 'field', :rhs_value => field_1.id, :rhs_which => 2,
          :operator => 'equals'
        })
        dataset = mock('dataset')

        dataset.expects(:filter).with(sequel_expr(:first_name => :last_name)).returns(dataset)
        assert_equal dataset, comparison_1.apply(dataset)

        dataset.expects(:filter).with(sequel_expr(:last_name => :first_name)).returns(dataset)
        assert_equal dataset, comparison_2.apply(dataset)
      end

      def test_apply_same_row_field_equality_to_one_side_only
        field_1 = @resource.fields_dataset[:name => 'first_name']
        field_2 = @resource.fields_dataset[:name => 'last_name']
        comparison_1 = Factory(:comparison, {
          :lhs_type => 'field', :lhs_value => field_1.id, :lhs_which => 1,
          :rhs_type => 'field', :rhs_value => field_2.id, :rhs_which => 1,
          :operator => 'equals'
        })
        comparison_2 = Factory(:comparison, {
          :lhs_type => 'field', :lhs_value => field_2.id, :lhs_which => 2,
          :rhs_type => 'field', :rhs_value => field_1.id, :rhs_which => 2,
          :operator => 'equals'
        })
        dataset_1 = mock('dataset')
        dataset_2 = mock('dataset')

        dataset_1.expects(:filter).with(sequel_expr(:first_name => :last_name)).returns(dataset_1)
        assert_equal dataset_1, comparison_1.apply(dataset_1, 0)
        dataset_1.expects(:filter).never
        assert_equal dataset_1, comparison_2.apply(dataset_1, 0)

        dataset_2.expects(:filter).never
        assert_equal dataset_2, comparison_1.apply(dataset_2, 1)
        dataset_2.expects(:filter).with(sequel_expr(:last_name => :first_name)).returns(dataset_2)
        assert_equal dataset_2, comparison_2.apply(dataset_2, 1)
      end

=begin
      def test_apply_field_greater_than_field
        field_1 = @resource.fields_dataset[:name => 'first_name']
        field_2 = @resource.fields_dataset[:name => 'last_name']
        comparison = Factory(:comparison, {
          :lhs_type => 'field', :lhs_value => field_1.id, :lhs_which => 1,
          :rhs_type => 'field', :rhs_value => field_2.id, :rhs_which => 2,
          :operator => 'greater_than'
        })
        dataset = mock('dataset', :opts => {})
        dataset.expects(:clone).with({:select => [:first_name, :last_name]}).returns(dataset)
        dataset.expects(:filter).with(~{:first_name => nil}, ~{:last_name => nil}).returns(dataset)
        assert_equal dataset, comparison.apply(dataset)
      end
=end

      def test_apply_does_not_duplicate_selects_or_orders
        field_1 = @resource.fields_dataset[:name => 'first_name']
        field_2 = @resource.fields_dataset[:name => 'last_name']
        comparison = Factory(:comparison, {
          :lhs_type => 'field', :lhs_value => field_1.id, :lhs_which => 1,
          :rhs_type => 'field', :rhs_value => field_2.id, :rhs_which => 2,
          :operator => 'equals'
        })
        dataset = mock('dataset', :opts => { :order => [:first_name], :select => [:foo, :first_name] })
        dataset.expects(:clone).with({:select => [:foo, :first_name, :last_name], :order => [:first_name, :last_name]}).returns(dataset)
        dataset.expects(:filter).with(~{:last_name => nil}).returns(dataset)
        assert_equal dataset, comparison.apply(dataset)
      end

      def test_apply_field_equals_non_field_indifferently
        field_1 = @resource.fields_dataset[:name => 'first_name']
        field_2 = @resource.fields_dataset[:name => 'last_name']
        comparison_1 = Factory(:comparison, {
          :lhs_type => 'field', :lhs_value => field_1.id, :lhs_which => 1,
          :rhs_type => 'integer', :rhs_value => 123,
          :operator => 'equals'
        })
        comparison_2 = Factory(:comparison, {
          :lhs_type => 'field', :lhs_value => field_2.id, :lhs_which => 2,
          :rhs_type => 'integer', :rhs_value => 123,
          :operator => 'equals'
        })
        dataset = mock('dataset')
        dataset.expects(:filter).with(sequel_expr({:first_name => 123})).returns(dataset)
        assert_equal dataset, comparison_1.apply(dataset)
        dataset.expects(:filter).with(sequel_expr({:last_name => 123})).returns(dataset)
        assert_equal dataset, comparison_2.apply(dataset)
      end

      def test_apply_field_equals_non_field_to_one_side_only
        field_1 = @resource.fields_dataset[:name => 'first_name']
        field_2 = @resource.fields_dataset[:name => 'last_name']
        comparison_1 = Factory(:comparison, {
          :lhs_type => 'field', :lhs_value => field_1.id, :lhs_which => 1,
          :rhs_type => 'integer', :rhs_value => 123,
          :operator => 'equals'
        })
        comparison_2 = Factory(:comparison, {
          :lhs_type => 'field', :lhs_value => field_2.id, :lhs_which => 2,
          :rhs_type => 'integer', :rhs_value => 123,
          :operator => 'equals'
        })
        dataset_1 = mock('dataset 1')
        dataset_2 = mock('dataset 2')

        dataset_1.expects(:filter).with(sequel_expr({:first_name => 123})).returns(dataset_1)
        assert_equal dataset_1, comparison_1.apply(dataset_1, 0)
        dataset_1.expects(:filter).never
        assert_equal dataset_1, comparison_2.apply(dataset_1, 0)

        dataset_2.expects(:filter).never
        assert_equal dataset_2, comparison_1.apply(dataset_2, 1)
        dataset_2.expects(:filter).with(sequel_expr({:last_name => 123})).returns(dataset_2)
        assert_equal dataset_2, comparison_2.apply(dataset_2, 1)
      end

      def test_apply_non_field_equals_field
        field = @resource.fields_dataset[:name => 'first_name']
        comparison = Factory(:comparison, {
          :lhs_type => 'integer', :lhs_value => 123,
          :rhs_type => 'field', :rhs_value => field.id, :rhs_which => 1,
          :operator => 'equals'
        })
        dataset = mock('dataset')
        dataset.expects(:filter).with(sequel_expr({123 => :first_name})).returns(dataset)
        assert_equal dataset, comparison.apply(dataset)
      end

      def test_apply_field_does_not_equal_non_field
        field = @resource.fields_dataset[:name => 'first_name']
        comparison = Factory(:comparison, {
          :lhs_type => 'field', :lhs_value => field.id,
          :rhs_type => 'integer', :rhs_value => 123,
          :operator => 'does_not_equal'
        })
        dataset = mock('dataset')
        dataset.expects(:filter).with(sequel_expr(~{:first_name => 123})).returns(dataset)
        assert_equal dataset, comparison.apply(dataset)
      end

      def test_apply_non_field_does_not_equal_field
        field = @resource.fields_dataset[:name => 'first_name']
        comparison = Factory(:comparison, {
          :lhs_type => 'integer', :lhs_value => 123,
          :rhs_type => 'field', :rhs_value => field.id,
          :operator => 'does_not_equal'
        })
        dataset = mock('dataset')
        dataset.expects(:filter).with(sequel_expr(~{123 => field.name.to_sym})).returns(dataset)
        assert_equal dataset, comparison.apply(dataset)
      end

      def test_apply_field_greater_than_non_field
        field = @resource.fields_dataset[:name => 'first_name']
        comparison = Factory(:comparison, {
          :lhs_type => 'field', :lhs_value => field.id,
          :rhs_type => 'integer', :rhs_value => 123,
          :operator => 'greater_than'
        })
        dataset = mock('dataset')
        dataset.expects(:filter).with(sequel_expr(field.name.to_sym > 123)).returns(dataset)
        assert_equal dataset, comparison.apply(dataset)
      end

      def test_apply_non_field_greater_than_field
        field = @resource.fields_dataset[:name => 'first_name']
        comparison = Factory(:comparison, {
          :lhs_type => 'integer', :lhs_value => 123,
          :rhs_type => 'field', :rhs_value => field.id,
          :operator => 'greater_than'
        })
        dataset = mock('dataset')
        dataset.expects(:filter).with(sequel_expr(:'>', 123, field.name.to_sym)).returns(dataset)
        assert_equal dataset, comparison.apply(dataset)
      end

      def test_apply_field_less_than_non_field
        field = @resource.fields_dataset[:name => 'first_name']
        comparison = Factory(:comparison, {
          :lhs_type => 'field', :lhs_value => field.id,
          :rhs_type => 'integer', :rhs_value => 123,
          :operator => 'less_than'
        })
        dataset = mock('dataset')
        dataset.expects(:filter).with(sequel_expr(field.name.to_sym < 123)).returns(dataset)
        assert_equal dataset, comparison.apply(dataset)
      end

      def test_apply_non_field_less_than_field
        field = @resource.fields_dataset[:name => 'first_name']
        comparison = Factory(:comparison, {
          :lhs_type => 'integer', :lhs_value => 123,
          :rhs_type => 'field', :rhs_value => field.id,
          :operator => 'less_than'
        })
        dataset = mock('dataset')
        dataset.expects(:filter).with(Sequel::SQL::BooleanExpression.new(:'<', 123, field.name.to_sym)).returns(dataset)
        assert_equal dataset, comparison.apply(dataset)
      end

      def test_apply_non_field_equal_non_field
        comparison = Factory(:comparison, {
          :lhs_type => 'integer', :lhs_value => 123,
          :rhs_type => 'integer', :rhs_value => 123,
          :operator => 'equals'
        })
        dataset = mock('dataset')
        dataset.expects(:filter).with(sequel_expr(123 => 123)).returns(dataset)
        assert_equal dataset, comparison.apply(dataset)
      end

      def test_apply_non_field_equal_non_field_regardless_of_side
        comparison = Factory(:comparison, {
          :lhs_type => 'integer', :lhs_value => 123,
          :rhs_type => 'integer', :rhs_value => 123,
          :operator => 'equals'
        })
        dataset_1 = mock('dataset 1')
        dataset_2 = mock('dataset 2')

        dataset_1.expects(:filter).with(sequel_expr(123 => 123)).returns(dataset_1)
        assert_equal dataset_1, comparison.apply(dataset_1, 0)
        dataset_2.expects(:filter).with(sequel_expr(123 => 123)).returns(dataset_2)
        assert_equal dataset_2, comparison.apply(dataset_2, 1)
      end

      def test_blocking?
        field = @resource.fields_dataset[:name => 'first_name']
        comparison = Factory(:comparison, {
          :lhs_type => 'field', :lhs_value => field.id, :lhs_which => 1,
          :rhs_type => 'field', :rhs_value => field.id, :rhs_which => 2,
          :operator => 'equals'
        })
        assert !comparison.blocking?
      end

      def test_cross_match?
        field_1 = @resource.fields_dataset[:name => 'first_name']
        field_2 = @resource.fields_dataset[:name => 'last_name']
        comparison = Factory(:comparison, {
          :lhs_type => 'field', :lhs_value => field_1.id, :lhs_which => 1,
          :rhs_type => 'field', :rhs_value => field_2.id, :rhs_which => 2,
          :operator => 'equals'
        })
        assert comparison.cross_match?
      end

      def test_does_not_allow_two_fields_of_different_types
        field_1 = @resource.fields_dataset[:name => 'first_name']
        field_2 = @resource.fields_dataset[:name => 'age']
        comparison = Factory.build(:comparison, {
          :lhs_type => 'field', :lhs_value => field_1.id, :lhs_which => 1,
          :rhs_type => 'field', :rhs_value => field_2.id, :rhs_which => 2,
          :operator => 'equals'
        })
        assert !comparison.valid?, "Comparison should have been invalid"
      end

      def test_does_not_allow_non_equality_comparisons_for_fields
        field = @resource.fields_dataset[:name => 'first_name']
        comparison = Factory.build(:comparison, {
          :lhs_type => 'field', :lhs_value => field.id, :lhs_which => 1,
          :rhs_type => 'field', :rhs_value => field.id, :rhs_which => 2,
          :operator => 'greater_than'
        })
        assert !comparison.valid?, "Comparison should have been invalid"
      end
    end
  end
end
