require File.dirname(__FILE__) + '/../../../helper'

module Coupler
  module Models
    class Scenario
      class TestRunner < Test::Unit::TestCase
        def test_single_dataset_and_one_field_to_field_equality_comparison
          project = Factory(:project)
          resource = Factory(:resource, :project => project)
          first_name = resource.fields_dataset[:name => 'first_name']
          scenario = Factory(:scenario, :project => project, :resource_1_id => resource.id)
          matcher = Factory(:matcher, {
            :scenario => scenario,
            :comparisons_attributes => [{
              :lhs_type => 'field', :lhs_value => first_name.id,
              :rhs_type => 'field', :rhs_value => first_name.id,
              :operator => 'equals'
            }]
          })
          matcher_id = matcher.id

          dataset = stub("Dataset")
          dataset.expects(:select).with(:id, :first_name).returns(dataset)
          dataset.expects(:filter).with(~{:first_name => nil}).returns(dataset)
          dataset.expects(:limit).with(1000, 0).returns(dataset)
          dataset.expects(:order).with(:first_name).returns(dataset)
          records = [
            [{:id => 5, :first_name => "Harry"}],
            [{:id => 6, :first_name => "Harry"}],
            [{:id => 9, :first_name => "Harry"}],
            [{:id => 3, :first_name => "Ron"}],
            [{:id => 8, :first_name => "Ron"}]
          ]
          dataset.expects(:each).multiple_yields(*records)
          scenario.resource_1.stubs(:final_dataset).yields(dataset)

          score_set = stub("ScoreSet")
          score_set.expects(:import).with(
            [:first_id, :second_id, :score, :matcher_id],
            [[5, 6, 100, matcher_id], [5, 9, 100, matcher_id], [6, 9, 100, matcher_id], [3, 8, 100, matcher_id]]
          )

          runner = SingleRunner.new(scenario)
          runner.run(score_set)
        end

        def test_single_dataset_and_two_field_to_field_equality_comparisons
          project = Factory(:project)
          resource = Factory(:resource, :project => project)
          first_name = resource.fields_dataset[:name => 'first_name']
          last_name = resource.fields_dataset[:name => 'last_name']
          scenario = Factory(:scenario, :project => project, :resource_1_id => resource.id)
          matcher = Factory(:matcher, {
            :scenario => scenario,
            :comparisons_attributes => [
              { :lhs_type => 'field', :lhs_value => first_name.id, :rhs_type => 'field', :rhs_value => first_name.id, :operator => 'equals' },
              { :lhs_type => 'field', :lhs_value => last_name.id, :rhs_type => 'field', :rhs_value => last_name.id, :operator => 'equals' }
            ]
          })
          matcher_id = matcher.id

          dataset = stub("Dataset")
          dataset.expects(:select).with(:id, :first_name, :last_name).returns(dataset)
          dataset.expects(:filter).with(~{:first_name => nil, :last_name => nil}).returns(dataset)
          dataset.expects(:limit).with(1000, 0).returns(dataset)
          dataset.expects(:order).with(:first_name, :last_name).returns(dataset)
          records = [
            [{:id => 5, :first_name => "Harry", :last_name => "Pewterschmidt"}],
            [{:id => 6, :first_name => "Harry", :last_name => "Potter"}],
            [{:id => 3, :first_name => "Harry", :last_name => "Potter"}],
            [{:id => 8, :first_name => "Ron", :last_name => "Skywalker"}]
          ]
          dataset.expects(:each).multiple_yields(*records)
          scenario.resource_1.stubs(:final_dataset).yields(dataset)

          score_set = stub("ScoreSet")
          score_set.expects(:import).with(
            [:first_id, :second_id, :score, :matcher_id],
            [[6, 3, 100, matcher_id]]
          )

          runner = SingleRunner.new(scenario)
          runner.run(score_set)
        end

        def test_single_dataset_and_cross_matching
          project = Factory(:project)
          resource = Factory(:resource, :project => project)
          first_name = resource.fields_dataset[:name => 'first_name']
          last_name = resource.fields_dataset[:name => 'last_name']
          scenario = Factory(:scenario, :project => project, :resource_1_id => resource.id)
          matcher = Factory(:matcher, {
            :scenario => scenario,
            :comparisons_attributes => [{
              :lhs_type => 'field', :lhs_value => first_name.id,
              :rhs_type => 'field', :rhs_value => last_name.id,
              :operator => 'equals'
            }]
          })
          matcher_id = matcher.id

          dataset = mock("Dataset")
          dataset.expects(:first_source_table).twice.returns(:people)
          dataset.expects(:from).with({:people => :t1}).returns(dataset)

          joined_dataset = mock("Joined dataset")
          dataset.expects(:join).with(:people, [~{:t2__id => :t1__id}, {:t2__last_name => :t1__first_name}], {:table_alias => :t2}).returns(joined_dataset)
          joined_dataset.expects(:select).with({:t1__id => :first_id, :t2__id => :second_id}).returns(joined_dataset)
          joined_dataset.expects(:filter).with(:t2__id > :t1__id, ~{:t1__first_name => nil, :t2__last_name => nil}).returns(joined_dataset)
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
          connection = Factory(:connection)
          project = Factory(:project)
          resource_1 = Factory(:resource, :table_name => "people", :project => project, :connection => connection)
          resource_2 = Factory(:resource, :table_name => "pets", :project => project, :connection => connection)
          first_name = resource_1.fields_dataset[:name => 'first_name']
          owner_first_name = resource_2.fields_dataset[:name => 'owner_first_name']
          scenario = Factory(:scenario, :project => project, :resource_1_id => resource_1.id, :resource_2_id => resource_2.id)
          matcher = Factory(:matcher, {
            :scenario => scenario,
            :comparisons_attributes => [{
              :lhs_type => 'field', :lhs_value => first_name.id,
              :rhs_type => 'field', :rhs_value => owner_first_name.id,
              :operator => 'equals'
            }]
          })
          matcher_id = matcher.id

          dataset_1 = mock("Dataset 1", :first_source_table => :people)
          dataset_2 = mock("Dataset 2", :first_source_table => :pets)
          joined_dataset = mock("Joined dataset")
          dataset_1.expects(:from).with({:people => :t1}).returns(dataset_1)
          dataset_1.expects(:join).with(:pets, [{:t2__owner_first_name => :t1__first_name}], {:table_alias => :t2}).returns(joined_dataset)
          joined_dataset.expects(:select).with({:t1__id => :first_id, :t2__id => :second_id}).returns(joined_dataset)
          joined_dataset.expects(:filter).with(~{:t1__first_name => nil, :t2__owner_first_name => nil}).returns(joined_dataset)
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
          connection = Factory(:connection)
          project = Factory(:project)
          resource_1 = Factory(:resource, :table_name => "people", :project => project, :connection => connection)
          resource_2 = Factory(:resource, :table_name => "pets", :project => project, :connection => connection)
          first_name = resource_1.fields_dataset[:name => 'first_name']
          last_name = resource_1.fields_dataset[:name => 'last_name']
          owner_first_name = resource_2.fields_dataset[:name => 'owner_first_name']
          owner_last_name = resource_2.fields_dataset[:name => 'owner_last_name']
          scenario = Factory(:scenario, :project => project, :resource_1_id => resource_1.id, :resource_2_id => resource_2.id)
          matcher = Factory(:matcher, {
            :scenario => scenario,
            :comparisons_attributes => [
              { :lhs_type => 'field', :lhs_value => first_name.id, :rhs_type => 'field', :rhs_value => owner_first_name.id, :operator => 'equals' },
              { :lhs_type => 'field', :lhs_value => last_name.id, :rhs_type => 'field', :rhs_value => owner_last_name.id, :operator => 'equals' }
            ]
          })
          matcher_id = matcher.id

          dataset_1 = mock("Dataset 1", :first_source_table => :people)
          dataset_2 = mock("Dataset 2", :first_source_table => :pets)
          joined_dataset = mock("Joined dataset")
          dataset_1.expects(:from).with({:people => :t1}).returns(dataset_1)
          dataset_1.expects(:join).with(:pets, [{:t2__owner_first_name => :t1__first_name, :t2__owner_last_name => :t1__last_name}], {:table_alias => :t2}).returns(joined_dataset)
          joined_dataset.expects(:select).with({:t1__id => :first_id, :t2__id => :second_id}).returns(joined_dataset)
          joined_dataset.expects(:filter).with(~{:t1__first_name => nil, :t2__owner_first_name => nil}, ~{:t1__last_name => nil, :t2__owner_last_name => nil}).returns(joined_dataset)
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
          project = Factory(:project)
          resource = Factory(:resource, :project => project)
          first_name = resource.fields_dataset[:name => 'first_name']
          scenario = Factory(:scenario, :project => project, :resource_1_id => resource.id)
          matcher = Factory(:matcher, {
            :scenario => scenario,
            :comparisons_attributes => [{
              :lhs_type => 'field', :lhs_value => first_name.id,
              :rhs_type => 'field', :rhs_value => first_name.id,
              :operator => 'equals'
            }]
          })
          matcher_id = matcher.id

          dataset = stub("Dataset")
          dataset.stubs(:select => dataset, :filter => dataset, :order => dataset)

          seq = sequence("selecting")
          dataset.expects(:limit).with(1000, 0).returns(dataset).in_sequence(seq)
          records_1 = Array.new(1000) { |i| [{:id => 123+i, :first_name => "Dude#{456+i}"}] }
          dataset.expects(:each).multiple_yields(*records_1).in_sequence(seq)

          dataset.expects(:limit).with(1000, 1000).returns(dataset).in_sequence(seq)
          records_2 = Array.new(123) { |i| [{:id => 1234+i, :first_name => "Dude#{4567+i}"}] }
          dataset.expects(:each).multiple_yields(*records_2).in_sequence(seq)
          scenario.resource_1.stubs(:final_dataset).yields(dataset)

          score_set = stub("ScoreSet", :import => nil)

          runner = SingleRunner.new(scenario)
          runner.run(score_set)
        end

        def test_score_with_two_datasets_uses_limit_correctly
          connection = Factory(:connection)
          project = Factory(:project)
          resource_1 = Factory(:resource, :table_name => "people", :project => project, :connection => connection)
          resource_2 = Factory(:resource, :table_name => "pets", :project => project, :connection => connection)
          first_name = resource_1.fields_dataset[:name => 'first_name']
          owner_first_name = resource_2.fields_dataset[:name => 'owner_first_name']
          scenario = Factory(:scenario, :project => project, :resource_1_id => resource_1.id, :resource_2_id => resource_2.id)
          matcher = Factory(:matcher, {
            :scenario => scenario,
            :comparisons_attributes => [{
              :lhs_type => 'field', :lhs_value => first_name.id,
              :rhs_type => 'field', :rhs_value => owner_first_name.id,
              :operator => 'equals'
            }]
          })
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
