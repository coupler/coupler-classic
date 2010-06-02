require File.dirname(__FILE__) + '/../../../helper'

module Coupler
  module Models
    class Scenario
      class TestRunner < Test::Unit::TestCase
        def setup
          super
          @connection = Factory(:connection)
          @project = Factory(:project)
          @resource_1 = Factory(:resource, :table_name => "people", :project => @project, :connection => @connection)
          @resource_2 = Factory(:resource, :table_name => "pets", :project => @project, :connection => @connection)
          @first_name = @resource_1.fields_dataset[:name => 'first_name']
          @last_name = @resource_1.fields_dataset[:name => 'last_name']
          @age = @resource_1.fields_dataset[:name => 'age']
          @owner_first_name = @resource_2.fields_dataset[:name => 'owner_first_name']
          @owner_last_name = @resource_2.fields_dataset[:name => 'owner_last_name']
        end

        def create_matcher_for(scenario, *comparisons)
          comparisons.collect! do |comparison|
            op = comparison.length == 3 ? comparison.pop : 'equals'
            types = comparison.collect do |value|
              case value
              when Field then 'field'
              when Fixnum then 'integer'
              when String then 'string'
              end
            end
            { 'lhs_type' => types[0], 'lhs_value' => types[0] == 'field' ? comparison[0].id : comparison[0],
              'rhs_type' => types[1], 'rhs_value' => types[1] == 'field' ? comparison[1].id : comparison[1],
              'operator' => op }
          end
          Factory(:matcher, :scenario => scenario, :comparisons_attributes => comparisons)
        end

        def test_single_dataset_and_one_field_to_field_equality_comparison
          scenario = Factory(:scenario, :project => @project, :resource_1_id => @resource_1.id)
          matcher = create_matcher_for(scenario, [@first_name, @first_name])
          matcher_id = matcher.id

          dataset = mock("Dataset")
          dataset.expects(:first_source_table).twice.returns(:people)
          dataset.expects(:from).with({:people => :t1}).returns(dataset)

          joined_dataset = mock("Joined dataset")
          dataset.expects(:join).with(:people, [:t1__id < :t2__id, {:t1__first_name => :t2__first_name}], {:table_alias => :t2}).returns(joined_dataset)
          joined_dataset.expects(:select).with({:t1__id => :first_id, :t2__id => :second_id}).returns(joined_dataset)
          joined_dataset.expects(:filter).with(~{:t1__first_name => nil}, ~{:t2__first_name => nil}).returns(joined_dataset)
          joined_dataset.expects(:limit).with(1000, 0).returns(joined_dataset)
          joined_dataset.expects(:each).multiple_yields([{:first_id => 123, :second_id => 456}], [{:first_id => 789, :second_id => 369}])
          joined_dataset.expects(:order).with(:t1__id, :t2__id).returns(joined_dataset)

          scenario.resource_1.stubs(:final_dataset).yields(dataset)

          score_set = stub("ScoreSet")
          score_set.expects(:import).with(
            [:first_id, :second_id, :score, :matcher_id],
            [[123, 456, 100, matcher_id], [789, 369, 100, matcher_id]]
          )

          runner = SingleRunner.new(scenario)
          runner.run(score_set)
        end

        def test_single_dataset_with_a_greater_than_comparison
          scenario = Factory(:scenario, :project => @project, :resource_1_id => @resource_1.id)
          matcher = create_matcher_for(scenario, [@first_name, @first_name], [@age, 30, 'greater_than'])
          matcher_id = matcher.id

          dataset = mock("Dataset")
          dataset.expects(:first_source_table).twice.returns(:people)
          dataset.expects(:from).with({:people => :t1}).returns(dataset)

          joined_dataset = mock("Joined dataset")
          dataset.expects(:join).with(:people, [:t1__id < :t2__id, {:t1__first_name => :t2__first_name}], {:table_alias => :t2}).returns(joined_dataset)
          joined_dataset.expects(:select).with({:t1__id => :first_id, :t2__id => :second_id}).returns(joined_dataset)
          joined_dataset.expects(:filter).with(~{:t1__first_name => nil}, ~{:t2__first_name => nil}, ~{:t1__age => nil}, :t1__age > 30).returns(joined_dataset)
          joined_dataset.expects(:limit).with(1000, 0).returns(joined_dataset)
          joined_dataset.expects(:each).multiple_yields([{:first_id => 123, :second_id => 456}], [{:first_id => 789, :second_id => 369}])
          joined_dataset.expects(:order).with(:t1__id, :t2__id).returns(joined_dataset)

          scenario.resource_1.stubs(:final_dataset).yields(dataset)

          score_set = stub("ScoreSet")
          score_set.expects(:import).with(
            [:first_id, :second_id, :score, :matcher_id],
            [[123, 456, 100, matcher_id], [789, 369, 100, matcher_id]]
          )

          runner = SingleRunner.new(scenario)
          runner.run(score_set)
        end

        def test_single_dataset_and_two_field_to_field_equality_comparisons
          scenario = Factory(:scenario, :project => @project, :resource_1_id => @resource_1.id)
          matcher = create_matcher_for(scenario, [@first_name, @first_name], [@last_name, @last_name])
          matcher_id = matcher.id

          dataset = mock("Dataset")
          dataset.expects(:first_source_table).twice.returns(:people)
          dataset.expects(:from).with({:people => :t1}).returns(dataset)

          joined_dataset = mock("Joined dataset")
          dataset.expects(:join).with(:people, [:t1__id < :t2__id, {:t1__first_name => :t2__first_name}, {:t1__last_name => :t2__last_name}], {:table_alias => :t2}).returns(joined_dataset)
          joined_dataset.expects(:select).with({:t1__id => :first_id, :t2__id => :second_id}).returns(joined_dataset)
          joined_dataset.expects(:filter).with(~{:t1__first_name => nil}, ~{:t2__first_name => nil}, ~{:t1__last_name => nil}, ~{:t2__last_name => nil}).returns(joined_dataset)
          joined_dataset.expects(:limit).with(1000, 0).returns(joined_dataset)
          joined_dataset.expects(:each).multiple_yields([{:first_id => 123, :second_id => 456}], [{:first_id => 789, :second_id => 369}])
          joined_dataset.expects(:order).with(:t1__id, :t2__id).returns(joined_dataset)

          scenario.resource_1.stubs(:final_dataset).yields(dataset)

          score_set = stub("ScoreSet")
          score_set.expects(:import).with(
            [:first_id, :second_id, :score, :matcher_id],
            [[123, 456, 100, matcher_id], [789, 369, 100, matcher_id]]
          )

          runner = SingleRunner.new(scenario)
          runner.run(score_set)
        end

        def test_single_dataset_and_cross_matching
          scenario = Factory(:scenario, :project => @project, :resource_1_id => @resource_1.id)
          matcher = create_matcher_for(scenario, [@first_name, @last_name])
          matcher_id = matcher.id

          dataset = mock("Dataset")
          dataset.expects(:first_source_table).twice.returns(:people)
          dataset.expects(:from).with({:people => :t1}).returns(dataset)

          joined_dataset = mock("Joined dataset")
          dataset.expects(:join).with(:people, [:t1__id < :t2__id, {:t1__first_name => :t2__last_name}], {:table_alias => :t2}).returns(joined_dataset)
          joined_dataset.expects(:select).with({:t1__id => :first_id, :t2__id => :second_id}).returns(joined_dataset)
          joined_dataset.expects(:filter).with(~{:t1__first_name => nil}, ~{:t2__last_name => nil}).returns(joined_dataset)
          joined_dataset.expects(:limit).with(1000, 0).returns(joined_dataset)
          joined_dataset.expects(:each).multiple_yields([{:first_id => 123, :second_id => 456}], [{:first_id => 789, :second_id => 369}])
          joined_dataset.expects(:order).with(:t1__id, :t2__id).returns(joined_dataset)

          scenario.resource_1.stubs(:final_dataset).yields(dataset)

          score_set = stub("ScoreSet")
          score_set.expects(:import).with(
            [:first_id, :second_id, :score, :matcher_id],
            [[123, 456, 100, matcher_id], [789, 369, 100, matcher_id]]
          )

          runner = SingleRunner.new(scenario)
          runner.run(score_set)
        end

        def test_two_datasets_with_one_field_to_field_equality_comparison
          scenario = Factory(:scenario, :project => @project, :resource_1_id => @resource_1.id, :resource_2_id => @resource_2.id)
          matcher = create_matcher_for(scenario, [@first_name, @owner_first_name])
          matcher_id = matcher.id

          dataset_1 = mock("Dataset 1", :first_source_table => :people)
          dataset_2 = mock("Dataset 2", :first_source_table => :pets)
          joined_dataset = mock("Joined dataset")
          dataset_1.expects(:from).with({:people => :t1}).returns(dataset_1)
          dataset_1.expects(:join).with(:pets, [{:t1__first_name => :t2__owner_first_name}], {:table_alias => :t2}).returns(joined_dataset)
          joined_dataset.expects(:select).with({:t1__id => :first_id, :t2__id => :second_id}).returns(joined_dataset)
          joined_dataset.expects(:filter).with(~{:t1__first_name => nil}, ~{:t2__owner_first_name => nil}).returns(joined_dataset)
          joined_dataset.expects(:limit).with(1000, 0).returns(joined_dataset)
          joined_dataset.expects(:each).multiple_yields([{:first_id => 123, :second_id => 456}], [{:first_id => 789, :second_id => 369}])
          joined_dataset.expects(:order).with(:t1__id, :t2__id).returns(joined_dataset)
          scenario.resource_1.stubs(:final_dataset).yields(dataset_1)
          scenario.resource_2.stubs(:final_dataset).yields(dataset_2)

          score_set = stub("ScoreSet")
          score_set.expects(:import).with(
            [:first_id, :second_id, :score, :matcher_id],
            [[123, 456, 100, matcher_id], [789, 369, 100, matcher_id]]
          )

          runner = DualRunner.new(scenario)
          runner.run(score_set)
        end

        def test_two_datasets_with_two_field_to_field_equality_comparisons
          scenario = Factory(:scenario, :project => @project, :resource_1_id => @resource_1.id, :resource_2_id => @resource_2.id)
          matcher = create_matcher_for(scenario, [@first_name, @owner_first_name], [@last_name, @owner_last_name])
          matcher_id = matcher.id

          dataset_1 = mock("Dataset 1", :first_source_table => :people)
          dataset_2 = mock("Dataset 2", :first_source_table => :pets)
          joined_dataset = mock("Joined dataset")
          dataset_1.expects(:from).with({:people => :t1}).returns(dataset_1)
          dataset_1.expects(:join).with(:pets, [{:t1__first_name => :t2__owner_first_name}, {:t1__last_name => :t2__owner_last_name}], {:table_alias => :t2}).returns(joined_dataset)
          joined_dataset.expects(:select).with({:t1__id => :first_id, :t2__id => :second_id}).returns(joined_dataset)
          joined_dataset.expects(:filter).with(~{:t1__first_name => nil}, ~{:t2__owner_first_name => nil}, ~{:t1__last_name => nil}, ~{:t2__owner_last_name => nil}).returns(joined_dataset)
          joined_dataset.expects(:limit).with(1000, 0).returns(joined_dataset)
          joined_dataset.expects(:each).multiple_yields([{:first_id => 123, :second_id => 456}], [{:first_id => 789, :second_id => 369}])
          joined_dataset.expects(:order).with(:t1__id, :t2__id).returns(joined_dataset)
          scenario.resource_1.stubs(:final_dataset).yields(dataset_1)
          scenario.resource_2.stubs(:final_dataset).yields(dataset_2)

          score_set = stub("ScoreSet")
          score_set.expects(:import).with(
            [:first_id, :second_id, :score, :matcher_id],
            [[123, 456, 100, matcher_id], [789, 369, 100, matcher_id]]
          )

          runner = DualRunner.new(scenario)
          runner.run(score_set)
        end

        def test_single_dataset_uses_limit_correctly
          scenario = Factory(:scenario, :project => @project, :resource_1_id => @resource_1.id)
          matcher = create_matcher_for(scenario, [@first_name, @first_name])
          matcher_id = matcher.id

          dataset = stub("Dataset", :first_source_table => :people)
          joined_dataset = stub("Joined dataset")
          dataset.stubs(:from => dataset, :join => joined_dataset)
          joined_dataset.stubs(:select => joined_dataset, :filter => joined_dataset, :order => joined_dataset)

          seq = sequence("selecting")
          joined_dataset.expects(:limit).with(1000, 0).returns(joined_dataset).in_sequence(seq)
          records_1 = Array.new(1000) { |i| [{:first_id => 123+i, :second_id => 456+i}] }
          joined_dataset.expects(:each).multiple_yields(*records_1).in_sequence(seq)

          joined_dataset.expects(:limit).with(1000, 1000).returns(joined_dataset).in_sequence(seq)
          records_2 = Array.new(123) { |i| [{:first_id => 1234+i, :second_id => 4567+i}] }
          joined_dataset.expects(:each).multiple_yields(*records_2).in_sequence(seq)

          scenario.resource_1.stubs(:final_dataset).yields(dataset)

          score_set = stub("ScoreSet", :import => nil)

          runner = SingleRunner.new(scenario)
          runner.run(score_set)
        end

        def test_score_with_two_datasets_uses_limit_correctly
          scenario = Factory(:scenario, :project => @project, :resource_1_id => @resource_1.id, :resource_2_id => @resource_2.id)
          matcher = create_matcher_for(scenario, [@first_name, @owner_first_name])
          matcher_id = matcher.id

          dataset_1 = mock("Dataset 1", :first_source_table => :people)
          dataset_2 = mock("Dataset 2", :first_source_table => :pets)
          joined_dataset = mock("Joined dataset")
          dataset_1.stubs(:from => dataset_1, :join => joined_dataset)
          joined_dataset.stubs(:select => joined_dataset, :filter => joined_dataset, :order => joined_dataset)

          seq = sequence("selecting")
          joined_dataset.expects(:limit).with(1000, 0).returns(joined_dataset).in_sequence(seq)
          records_1 = Array.new(1000) { |i| [{:first_id => 123+i, :second_id => 456+i}] }
          joined_dataset.expects(:each).multiple_yields(*records_1).in_sequence(seq)

          joined_dataset.expects(:limit).with(1000, 1000).returns(joined_dataset).in_sequence(seq)
          records_2 = Array.new(123) { |i| [{:first_id => 1234+i, :second_id => 4567+i}] }
          joined_dataset.expects(:each).multiple_yields(*records_2).in_sequence(seq)

          scenario.resource_1.stubs(:final_dataset).yields(dataset_1)
          scenario.resource_2.stubs(:final_dataset).yields(dataset_2)

          score_set = stub("ScoreSet", :import => nil)

          runner = DualRunner.new(scenario)
          runner.run(score_set)
        end
      end
    end
  end
end
