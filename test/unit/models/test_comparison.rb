require 'helper'

module CouplerUnitTests
  module ModelTests
    class TestComparison < Coupler::Test::UnitTest
      def sequel_expr(*args)
        if args.length == 1
          obj = args[0]
          obj.is_a?(Sequel::SQL::BooleanExpression) ? obj : Sequel::SQL::BooleanExpression.from_value_pairs(obj)
        else
          Sequel::SQL::BooleanExpression.new(*args)
        end
      end

      def new_comparison(attribs = {})
        values = {
          :lhs_type      => "integer",
          :raw_lhs_value => 1,
          :rhs_type      => "integer",
          :raw_rhs_value => 1,
          :operator      => "equals",
          :matcher       => @matcher
        }.update(attribs)
        c = Comparison.new(values)
        c
      end

      def setup
        super
        @matcher = stub('matcher', :id => 123, :pk => 123, :associations => {})
      end

      test "sequel model" do
        assert_equal ::Sequel::Model, Comparison.superclass
        assert_equal :comparisons, Comparison.table_name
      end

      test "many to one matcher" do
        assert_respond_to Comparison.new, :matcher
      end

      #def test_serializes_lhs_and_rhs_values
        #comparison = new_comparison({
          #:lhs_type => "integer", :raw_lhs_value => 123,
          #:rhs_type => "integer", :raw_rhs_value => 123
        #}).save!
        #assert_equal 123, comparison.raw_lhs_value
        #assert_equal 123, comparison.raw_rhs_value
      #end

      test "requires values" do
        comparison = new_comparison({
          :raw_lhs_value => nil,
          :raw_rhs_value => nil
        })
        comparison.expects(:validates_presence).with { |fields|
          (fields - [:raw_lhs_value, :raw_rhs_value]).empty?
        }.returns(false)
        comparison.valid?
      end

      test "requires valid types" do
        comparison = new_comparison({
          :lhs_type => 'foo', :rhs_type => 'foo'
        })
        comparison.stubs(:validates_includes).at_least_once
        comparison.expects(:validates_includes).with(%w{field integer string}, [:lhs_type, :rhs_type]).returns(false)
        comparison.valid?
      end

      test "requires valid operator" do
        comparison = new_comparison({
          :operator => 'foo'
        })
        comparison.stubs(:validates_includes).at_least_once
        comparison.expects(:validates_includes).with(%w{equals does_not_equal greater_than less_than}, :operator).returns(false)
        comparison.valid?
      end

      test "requires valid lhs_which and rhs_which" do
        comparison = new_comparison({
          :raw_lhs_value => 1, :lhs_type => 'field', :lhs_which => 123,
          :raw_rhs_value => 2, :rhs_type => 'field', :rhs_which => 123
        })
        comparison.stubs(:validates_includes).at_least_once
        comparison.expects(:validates_includes).with([1, 2], :lhs_which).returns(false)
        comparison.expects(:validates_includes).with([1, 2], :rhs_which).returns(false)
        comparison.valid?
      end

      test "value methods return fields if type is field" do
        comparison = new_comparison({
          :lhs_type => "field", :raw_lhs_value => 1,
          :rhs_type => "field", :raw_rhs_value => 2
        }).save!

        field_1 = stub('field 1')
        field_2 = stub('field 2')
        Field.expects(:[]).with(:id => 1).returns(field_1)
        Field.expects(:[]).with(:id => 2).returns(field_2)

        assert_equal field_1, comparison.lhs_value
        assert_equal field_2, comparison.rhs_value
      end

      test "values are coerced to integer when type is integer" do
        comparison = new_comparison({
          :lhs_type => "integer", :raw_lhs_value => "123",
          :rhs_type => "integer", :raw_rhs_value => "123"
        }).save!

        assert_equal 123, comparison.raw_lhs_value
        assert_equal 123, comparison.raw_rhs_value
      end

      test "fields returns lhs field" do
        comparison = new_comparison({
          :lhs_type => "field", :raw_lhs_value => 1,
          :rhs_type => "integer", :raw_rhs_value => 123
        }).save!

        field = stub("field")
        Field.expects(:[]).with(:id => 1).returns(field)
        assert_equal [field], comparison.fields
      end

      test "fields returns rhs field" do
        comparison = new_comparison({
          :lhs_type => "integer", :raw_lhs_value => 123,
          :rhs_type => "field", :raw_rhs_value => 1,
        }).save!

        field = stub("field")
        Field.expects(:[]).with(:id => 1).returns(field)
        assert_equal [field], comparison.fields
      end

      test "fields returns two fields" do
        comparison = new_comparison({
          :lhs_type => "field", :raw_lhs_value => 1,
          :rhs_type => "field", :raw_rhs_value => 2
        }).save!

        field_1 = stub("field 1")
        field_2 = stub("field 2")
        Field.expects(:[]).with(:id => 1).returns(field_1)
        Field.expects(:[]).with(:id => 2).returns(field_2)
        assert_equal [field_1, field_2], comparison.fields
      end

      test "fields returns empty array" do
        comparison = new_comparison({
          :lhs_type => "integer", :raw_lhs_value => 123,
          :rhs_type => "integer", :raw_rhs_value => 123,
        }).save!
        assert_equal [], comparison.fields
      end

      test "operator symbol" do
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
        test "#{name}_label" do
          resource = stub("resource", :name => "foo")
          field = stub("field", :name => "ssn", :resource => resource)
          Field.stubs(:[]).with(:id => 1).returns(field)

          comparison = Comparison.new(:"#{name}_type" => 'field', :"raw_#{name}_value" => 1)
          assert_equal "ssn (foo)", comparison.send("#{name}_label")

          comparison.send("#{name}_which=", 1)
          assert_equal %{ssn (foo<span class="sup">1</span>)}, comparison.send("#{name}_label")

          comparison.send("#{name}_which=", 2)
          assert_equal %{ssn (foo<span class="sup">2</span>)}, comparison.send("#{name}_label")

          comparison.send("#{name}_type=", 'integer')
          comparison.send("raw_#{name}_value=", 123)
          assert_equal "123", comparison.send("#{name}_label")

          comparison.send("#{name}_type=", 'string')
          comparison.send("raw_#{name}_value=", 'foo')
          assert_equal %{"foo"}, comparison.send("#{name}_label")
        end
      end

      test "apply field equality" do
        comparison = new_comparison({
          :lhs_type => 'field', :raw_lhs_value => 1, :lhs_which => 1,
          :rhs_type => 'field', :raw_rhs_value => 1, :rhs_which => 2,
          :operator => 'equals'
        }).save!

        field = stub("field", :name => "first_name")
        Field.stubs(:[]).with(:id => 1).returns(field)
        dataset = mock('dataset', :opts => {})
        dataset.expects(:clone).with({:select => [:first_name], :order => [:first_name]}).returns(dataset)
        dataset.expects(:filter).with(~{:first_name => nil}).returns(dataset)
        assert_equal dataset, comparison.apply(dataset)
      end

      test "apply field equality to one side only" do
        comparison = new_comparison({
          :lhs_type => 'field', :raw_lhs_value => 1, :lhs_which => 1,
          :rhs_type => 'field', :raw_rhs_value => 1, :rhs_which => 2,
          :operator => 'equals'
        }).save!

        field = stub("field", :name => "first_name")
        Field.stubs(:[]).with(:id => 1).returns(field)
        dataset_1 = mock('dataset', :opts => {})
        dataset_1.expects(:clone).with({:select => [:first_name], :order => [:first_name]}).returns(dataset_1)
        dataset_1.expects(:filter).with(~{:first_name => nil}).returns(dataset_1)
        dataset_2 = mock('dataset', :opts => {})
        dataset_2.expects(:clone).with({:select => [:first_name], :order => [:first_name]}).returns(dataset_2)
        dataset_2.expects(:filter).with(~{:first_name => nil}).returns(dataset_2)

        assert_equal dataset_1, comparison.apply(dataset_1, 0)
        assert_equal dataset_2, comparison.apply(dataset_2, 1)
      end

      test "apply two field equality" do
        comparison = new_comparison({
          :lhs_type => 'field', :raw_lhs_value => 1, :lhs_which => 1,
          :rhs_type => 'field', :raw_rhs_value => 2, :rhs_which => 2,
          :operator => 'equals'
        }).save!

        field_1 = stub("field 1", :name => 'ssn_1')
        field_2 = stub("field 2", :name => 'ssn_2')
        Field.stubs(:[]).with(:id => 1).returns(field_1)
        Field.stubs(:[]).with(:id => 2).returns(field_2)
        dataset = mock('dataset', :opts => {})
        dataset.expects(:clone).with({:select => [:ssn_1, :ssn_2], :order => [:ssn_1, :ssn_2]}).returns(dataset)
        dataset.expects(:filter).with(~{:ssn_1 => nil}, ~{:ssn_2 => nil}).returns(dataset)
        assert_equal dataset, comparison.apply(dataset)
      end

      test "apply two field equality to one side only" do
        comparison = new_comparison({
          :lhs_type => 'field', :raw_lhs_value => 1, :lhs_which => 1,
          :rhs_type => 'field', :raw_rhs_value => 2, :rhs_which => 2,
          :operator => 'equals'
        }).save!

        field_1 = stub("field 1", :name => 'ssn_1')
        field_2 = stub("field 2", :name => 'ssn_2')
        Field.stubs(:[]).with(:id => 1).returns(field_1)
        Field.stubs(:[]).with(:id => 2).returns(field_2)
        dataset_1 = mock('dataset', :opts => {})
        dataset_1.expects(:clone).with({:select => [:ssn_1], :order => [:ssn_1]}).returns(dataset_1)
        dataset_1.expects(:filter).with(~{:ssn_1 => nil}).returns(dataset_1)
        dataset_2 = mock('dataset', :opts => {})
        dataset_2.expects(:clone).with({:select => [:ssn_2], :order => [:ssn_2]}).returns(dataset_2)
        dataset_2.expects(:filter).with(~{:ssn_2 => nil}).returns(dataset_2)

        assert_equal dataset_1, comparison.apply(dataset_1, 0)
        assert_equal dataset_2, comparison.apply(dataset_2, 1)
      end

=begin
      def test_apply_field_inequality_to_single_dataset
        field = stub("field", :name => 'first_name')
        Field.stubs(:[]).with(:id => 1).returns(field)
        comparison = new_comparison({
          :lhs_type => 'field', :raw_lhs_value => 1, :lhs_which => 1,
          :rhs_type => 'field', :raw_rhs_value => 1, :rhs_which => 2,
          :operator => 'does_not_equal'
        }).save!
        dataset = mock('dataset', :opts => {})
        dataset.expects(:clone).with({:select => [:first_name], :order => [:first_name]}).returns(dataset)
        dataset.expects(:filter).with(~{:first_name => nil}).returns(dataset)
        assert_equal dataset, comparison.apply(dataset)
      end

      def test_apply_field_inequality_to_dual_datasets
        field = stub("field", :name => 'first_name')
        Field.stubs(:[]).with(:id => 1).returns(field)
        comparison = new_comparison({
          :lhs_type => 'field', :raw_lhs_value => 1, :lhs_which => 1,
          :rhs_type => 'field', :raw_rhs_value => 1, :rhs_which => 2,
          :operator => 'does_not_equal'
        }).save!
        dataset_1 = mock('dataset_1', :opts => {})
        dataset_1.expects(:clone).with({:select => [:first_name], :order => [:first_name]}).returns(dataset_1)
        dataset_1.expects(:filter).with(~{:first_name => nil}).returns(dataset_1)
        dataset_2 = mock('dataset_2', :opts => {})
        dataset_2.expects(:clone).with({:select => [:first_name], :order => [:first_name]}).returns(dataset_2)
        dataset_2.expects(:filter).with(~{:first_name => nil}).returns(dataset_2)
        assert_equal [dataset_1, dataset_2], comparison.apply(dataset_1, dataset_2)
      end
=end

      test "apply same row field equality indifferently" do
        comparison_1 = new_comparison({
          :lhs_type => 'field', :raw_lhs_value => 1, :lhs_which => 1,
          :rhs_type => 'field', :raw_rhs_value => 2, :rhs_which => 1,
          :operator => 'equals'
        }).save!
        comparison_2 = new_comparison({
          :lhs_type => 'field', :raw_lhs_value => 2, :lhs_which => 2,
          :rhs_type => 'field', :raw_rhs_value => 1, :rhs_which => 2,
          :operator => 'equals'
        }).save!

        field_1 = stub("field 1", :name => 'ssn_1')
        field_2 = stub("field 2", :name => 'ssn_2')
        Field.stubs(:[]).with(:id => 1).returns(field_1)
        Field.stubs(:[]).with(:id => 2).returns(field_2)
        dataset = mock('dataset')

        dataset.expects(:filter).with(sequel_expr(:ssn_1 => :ssn_2)).returns(dataset)
        assert_equal dataset, comparison_1.apply(dataset)

        dataset.expects(:filter).with(sequel_expr(:ssn_2 => :ssn_1)).returns(dataset)
        assert_equal dataset, comparison_2.apply(dataset)
      end

      test "apply same row field equality to one side only" do
        comparison_1 = new_comparison({
          :lhs_type => 'field', :raw_lhs_value => 1, :lhs_which => 1,
          :rhs_type => 'field', :raw_rhs_value => 2, :rhs_which => 1,
          :operator => 'equals'
        }).save!
        comparison_2 = new_comparison({
          :lhs_type => 'field', :raw_lhs_value => 2, :lhs_which => 2,
          :rhs_type => 'field', :raw_rhs_value => 1, :rhs_which => 2,
          :operator => 'equals'
        }).save!

        field_1 = stub("field 1", :name => 'ssn_1')
        field_2 = stub("field 2", :name => 'ssn_2')
        Field.stubs(:[]).with(:id => 1).returns(field_1)
        Field.stubs(:[]).with(:id => 2).returns(field_2)
        dataset_1 = mock('dataset')
        dataset_2 = mock('dataset')

        dataset_1.expects(:filter).with(sequel_expr(:ssn_1 => :ssn_2)).returns(dataset_1)
        assert_equal dataset_1, comparison_1.apply(dataset_1, 0)
        dataset_1.expects(:filter).never
        assert_equal dataset_1, comparison_2.apply(dataset_1, 0)

        dataset_2.expects(:filter).never
        assert_equal dataset_2, comparison_1.apply(dataset_2, 1)
        dataset_2.expects(:filter).with(sequel_expr(:ssn_2 => :ssn_1)).returns(dataset_2)
        assert_equal dataset_2, comparison_2.apply(dataset_2, 1)
      end

#=begin
      #def test_apply_field_greater_than_field
        #field_1 = @resource.fields_dataset[:name => 'first_name']
        #field_2 = @resource.fields_dataset[:name => 'last_name']
        #comparison = new_comparison({
          #:lhs_type => 'field', :raw_lhs_value => field_1.id, :lhs_which => 1,
          #:rhs_type => 'field', :raw_rhs_value => field_2.id, :rhs_which => 2,
          #:operator => 'greater_than'
        #}).save!
        #dataset = mock('dataset', :opts => {})
        #dataset.expects(:clone).with({:select => [:first_name, :last_name]}).returns(dataset)
        #dataset.expects(:filter).with(~{:first_name => nil}, ~{:last_name => nil}).returns(dataset)
        #assert_equal dataset, comparison.apply(dataset)
      #end
#=end

      test "apply does not duplicate selects or orders" do
        comparison = new_comparison({
          :lhs_type => 'field', :raw_lhs_value => 1, :lhs_which => 1,
          :rhs_type => 'field', :raw_rhs_value => 2, :rhs_which => 2,
          :operator => 'equals'
        }).save!

        field_1 = stub("field 1", :name => 'ssn_1')
        field_2 = stub("field 2", :name => 'ssn_2')
        Field.stubs(:[]).with(:id => 1).returns(field_1)
        Field.stubs(:[]).with(:id => 2).returns(field_2)
        dataset = mock('dataset', :opts => { :order => [:ssn_1], :select => [:foo, :ssn_1] })
        dataset.expects(:clone).with({:select => [:foo, :ssn_1, :ssn_2], :order => [:ssn_1, :ssn_2]}).returns(dataset)
        dataset.expects(:filter).with(~{:ssn_2 => nil}).returns(dataset)
        assert_equal dataset, comparison.apply(dataset)
      end

      test "apply field equals non field indifferently" do
        comparison_1 = new_comparison({
          :lhs_type => 'field', :raw_lhs_value => 1, :lhs_which => 1,
          :rhs_type => 'integer', :raw_rhs_value => 123,
          :operator => 'equals'
        }).save!
        comparison_2 = new_comparison({
          :lhs_type => 'field', :raw_lhs_value => 2, :lhs_which => 2,
          :rhs_type => 'integer', :raw_rhs_value => 123,
          :operator => 'equals'
        }).save!

        field_1 = stub("field 1", :name => 'ssn_1')
        field_2 = stub("field 2", :name => 'ssn_2')
        Field.stubs(:[]).with(:id => 1).returns(field_1)
        Field.stubs(:[]).with(:id => 2).returns(field_2)
        dataset = mock('dataset')
        dataset.expects(:filter).with(sequel_expr({:ssn_1 => 123})).returns(dataset)
        assert_equal dataset, comparison_1.apply(dataset)
        dataset.expects(:filter).with(sequel_expr({:ssn_2 => 123})).returns(dataset)
        assert_equal dataset, comparison_2.apply(dataset)
      end

      test "apply field equals non field to one side only" do
        comparison_1 = new_comparison({
          :lhs_type => 'field', :raw_lhs_value => 1, :lhs_which => 1,
          :rhs_type => 'integer', :raw_rhs_value => 123,
          :operator => 'equals'
        }).save!
        comparison_2 = new_comparison({
          :lhs_type => 'field', :raw_lhs_value => 2, :lhs_which => 2,
          :rhs_type => 'integer', :raw_rhs_value => 123,
          :operator => 'equals'
        }).save!

        field_1 = stub("field 1", :name => 'ssn_1')
        field_2 = stub("field 2", :name => 'ssn_2')
        Field.stubs(:[]).with(:id => 1).returns(field_1)
        Field.stubs(:[]).with(:id => 2).returns(field_2)
        dataset_1 = mock('dataset 1')
        dataset_2 = mock('dataset 2')

        dataset_1.expects(:filter).with(sequel_expr({:ssn_1 => 123})).returns(dataset_1)
        assert_equal dataset_1, comparison_1.apply(dataset_1, 0)
        dataset_1.expects(:filter).never
        assert_equal dataset_1, comparison_2.apply(dataset_1, 0)

        dataset_2.expects(:filter).never
        assert_equal dataset_2, comparison_1.apply(dataset_2, 1)
        dataset_2.expects(:filter).with(sequel_expr({:ssn_2 => 123})).returns(dataset_2)
        assert_equal dataset_2, comparison_2.apply(dataset_2, 1)
      end

      test "apply non field equals field" do
        field = stub("field", :name => 'first_name')
        Field.stubs(:[]).with(:id => 1).returns(field)
        comparison = new_comparison({
          :lhs_type => 'integer', :raw_lhs_value => 123,
          :rhs_type => 'field', :raw_rhs_value => 1, :rhs_which => 1,
          :operator => 'equals'
        }).save!
        dataset = mock('dataset')
        dataset.expects(:filter).with(sequel_expr({123 => :first_name})).returns(dataset)
        assert_equal dataset, comparison.apply(dataset)
      end

      test "apply field does not equal non field" do
        field = stub("field", :name => 'first_name')
        Field.stubs(:[]).with(:id => 1).returns(field)
        comparison = new_comparison({
          :lhs_type => 'field', :raw_lhs_value => 1,
          :rhs_type => 'integer', :raw_rhs_value => 123,
          :operator => 'does_not_equal'
        }).save!
        dataset = mock('dataset')
        dataset.expects(:filter).with(sequel_expr(~{:first_name => 123})).returns(dataset)
        assert_equal dataset, comparison.apply(dataset)
      end

      test "apply non field does not equal field" do
        field = stub("field", :name => 'first_name')
        Field.stubs(:[]).with(:id => 1).returns(field)
        comparison = new_comparison({
          :lhs_type => 'integer', :raw_lhs_value => 123,
          :rhs_type => 'field', :raw_rhs_value => 1,
          :operator => 'does_not_equal'
        }).save!
        dataset = mock('dataset')
        dataset.expects(:filter).with(sequel_expr(~{123 => :first_name})).returns(dataset)
        assert_equal dataset, comparison.apply(dataset)
      end

      test "apply field greater than non field" do
        field = stub("field", :name => 'first_name')
        Field.stubs(:[]).with(:id => 1).returns(field)
        comparison = new_comparison({
          :lhs_type => 'field', :raw_lhs_value => 1,
          :rhs_type => 'integer', :raw_rhs_value => 123,
          :operator => 'greater_than'
        }).save!
        dataset = mock('dataset')
        dataset.expects(:filter).with(sequel_expr(:first_name > 123)).returns(dataset)
        assert_equal dataset, comparison.apply(dataset)
      end

      test "apply non field greater than field" do
        field = stub("field", :name => 'first_name')
        Field.stubs(:[]).with(:id => 1).returns(field)
        comparison = new_comparison({
          :lhs_type => 'integer', :raw_lhs_value => 123,
          :rhs_type => 'field', :raw_rhs_value => 1,
          :operator => 'greater_than'
        }).save!
        dataset = mock('dataset')
        dataset.expects(:filter).with(sequel_expr(:'>', 123, :first_name)).returns(dataset)
        assert_equal dataset, comparison.apply(dataset)
      end

      test "apply field less than non field" do
        field = stub("field", :name => 'first_name')
        Field.stubs(:[]).with(:id => 1).returns(field)
        comparison = new_comparison({
          :lhs_type => 'field', :raw_lhs_value => 1,
          :rhs_type => 'integer', :raw_rhs_value => 123,
          :operator => 'less_than'
        }).save!
        dataset = mock('dataset')
        dataset.expects(:filter).with(sequel_expr(:first_name < 123)).returns(dataset)
        assert_equal dataset, comparison.apply(dataset)
      end

      test "apply non field less than field" do
        field = stub("field", :name => 'first_name')
        Field.stubs(:[]).with(:id => 1).returns(field)
        comparison = new_comparison({
          :lhs_type => 'integer', :raw_lhs_value => 123,
          :rhs_type => 'field', :raw_rhs_value => 1,
          :operator => 'less_than'
        }).save!
        dataset = mock('dataset')
        dataset.expects(:filter).with(Sequel::SQL::BooleanExpression.new(:'<', 123, :first_name)).returns(dataset)
        assert_equal dataset, comparison.apply(dataset)
      end

      test "apply non field equal non field" do
        comparison = new_comparison({
          :lhs_type => 'integer', :raw_lhs_value => 123,
          :rhs_type => 'integer', :raw_rhs_value => 123,
          :operator => 'equals'
        }).save!
        dataset = mock('dataset')
        dataset.expects(:filter).with(sequel_expr(123 => 123)).returns(dataset)
        assert_equal dataset, comparison.apply(dataset)
      end

      test "apply non field equal non field regardless of side" do
        comparison = new_comparison({
          :lhs_type => 'integer', :raw_lhs_value => 123,
          :rhs_type => 'integer', :raw_rhs_value => 123,
          :operator => 'equals'
        }).save!
        dataset_1 = mock('dataset 1')
        dataset_2 = mock('dataset 2')

        dataset_1.expects(:filter).with(sequel_expr(123 => 123)).returns(dataset_1)
        assert_equal dataset_1, comparison.apply(dataset_1, 0)
        dataset_2.expects(:filter).with(sequel_expr(123 => 123)).returns(dataset_2)
        assert_equal dataset_2, comparison.apply(dataset_2, 1)
      end

      test "blocking?" do
        field = stub("field", :name => 'first_name') {
          stubs(:[]).with(:final_type).returns('string')
        }
        Field.stubs(:[]).with(:id => 1).returns(field)
        comparison = new_comparison({
          :lhs_type => 'field', :raw_lhs_value => 1, :lhs_which => 1,
          :rhs_type => 'field', :raw_rhs_value => 1, :rhs_which => 2,
          :operator => 'equals'
        }).save!
        assert !comparison.blocking?
      end

      test "cross_match?" do
        field_1 = stub("field 1", :id => 1, :name => 'ssn_1', :resource_id => 1) {
          stubs(:[]).with(:final_type).returns('string')
        }
        Field.stubs(:[]).with(:id => 1).returns(field_1)
        field_2 = stub("field 2", :id => 2, :name => 'ssn_2', :resource_id => 1) {
          stubs(:[]).with(:final_type).returns('string')
        }
        Field.stubs(:[]).with(:id => 2).returns(field_2)
        comparison = new_comparison({
          :lhs_type => 'field', :raw_lhs_value => 1, :lhs_which => 1,
          :rhs_type => 'field', :raw_rhs_value => 2, :rhs_which => 2,
          :operator => 'equals'
        }).save!
        assert comparison.cross_match?
      end

      test "does not allow two fields of different types" do
        field_1 = stub("field 1", :name => 'first_name') {
          stubs(:[]).with(:final_type).returns('string')
        }
        Field.stubs(:[]).with(:id => 1).returns(field_1)
        field_2 = stub("field 2", :name => 'age') {
          stubs(:[]).with(:final_type).returns('integer')
        }
        Field.stubs(:[]).with(:id => 2).returns(field_2)
        comparison = new_comparison({
          :lhs_type => 'field', :raw_lhs_value => 1, :lhs_which => 1,
          :rhs_type => 'field', :raw_rhs_value => 2, :rhs_which => 2,
          :operator => 'equals'
        })
        assert !comparison.valid?, "Comparison should have been invalid"
      end

      test "does not allow non-equality comparisons for fields" do
        field = stub("field", :name => 'first_name') { stubs(:[]).with(:final_type).returns('string') }
        Field.stubs(:[]).with(:id => 1).returns(field)
        comparison = new_comparison({
          :lhs_type => 'field', :raw_lhs_value => 1, :lhs_which => 1,
          :rhs_type => 'field', :raw_rhs_value => 1, :rhs_which => 2,
          :operator => 'greater_than'
        })
        assert !comparison.valid?, "Comparison should have been invalid"
      end
    end
  end
end
