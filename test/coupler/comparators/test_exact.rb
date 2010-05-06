require File.dirname(__FILE__) + '/../../helper'

module Coupler
  module Comparators
    class TestExact < Test::Unit::TestCase
      def test_base_superclass
        assert_equal Base, Exact.superclass
      end

      def test_registers_itself
        assert Comparators.list.include?("exact")
      end

      def test_field_arity
        assert_equal :infinite, Exact.field_arity
      end

      def test_score_with_single_dataset_and_one_field
        dataset = stub("Dataset")
        dataset.expects(:select).with(:id, :first_name).returns(dataset)
        dataset.expects(:filter).with(~{:first_name => nil}).returns(dataset)
        dataset.expects(:limit).with(1000, 0).returns(dataset)
        dataset.expects(:order).with(:first_name).returns(dataset)
        records = [
          [{:id => 5, :first_name => "Harry"}],
          [{:id => 6, :first_name => "Harry"}],
          [{:id => 3, :first_name => "Ron"}],
          [{:id => 8, :first_name => "Ron"}]
        ]
        dataset.expects(:each).multiple_yields(*records)
        score_set = stub("ScoreSet")
        score_set.expects(:import).with(
          [:first_id, :second_id, :score, :matcher_id],
          [[5, 6, 100, 123], [3, 8, 100, 123]]
        )

        comparator = Exact.new({
          'field_names' => ['first_name'], 'keys' => ['id'],
          'matcher_id' => 123
        })
        comparator.score(score_set, dataset)
      end

      def test_score_with_single_dataset_and_two_fields
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
        score_set = stub("ScoreSet")
        score_set.expects(:import).with(
          [:first_id, :second_id, :score, :matcher_id],
          [[6, 3, 100, 123]]
        )

        comparator = Exact.new({
          'field_names' => ['first_name', 'last_name'], 'keys' => ['id'],
          'matcher_id' => 123
        })
        comparator.score(score_set, dataset)
      end

      def test_score_with_single_dataset_and_cross_matching
        dataset = mock("Dataset")
        dataset.expects(:first_source_table).twice.returns(:people)
        dataset.expects(:from).with({:people => :t1}).returns(dataset)
        joined_dataset = mock("Joined dataset")
        dataset.expects(:join).with(:people, [~{:t2__id => :t1__id}, {:t2__last_name => :t1__first_name}], {:table_alias => :t2}).returns(joined_dataset)
        joined_dataset.expects(:select).with({:t1__id => :first_id, :t2__id => :second_id}).returns(joined_dataset)
        joined_dataset.expects(:filter).with(~{:t1__first_name => nil, :t2__last_name => nil}).returns(joined_dataset)
        joined_dataset.expects(:limit).with(1000, 0).returns(joined_dataset)
        joined_dataset.expects(:each).multiple_yields([{:first_id => 123, :second_id => 456}], [{:first_id => 789, :second_id => 369}])
        joined_dataset.expects(:order).with(:t1__id, :t2__id).returns(joined_dataset)
        score_set = stub("ScoreSet")
        score_set.expects(:import).with(
          [:first_id, :second_id, :score, :matcher_id],
          [[123, 456, 100, 123], [789, 369, 100, 123]]
        )

        comparator = Exact.new({
          'field_names' => [['first_name', 'last_name']], 'keys' => ['id'],
          'matcher_id' => 123
        })
        comparator.score(score_set, dataset)
      end

      def test_score_with_two_datasets_and_one_field
        dataset_1 = mock("Dataset 1", :first_source_table => :people)
        dataset_2 = mock("Dataset 2", :first_source_table => :adults)
        joined_dataset = mock("Joined dataset")
        dataset_1.expects(:from).with({:people => :t1}).returns(dataset_1)
        dataset_1.expects(:join).with(:adults, [{:t2__first_name => :t1__first_name}], {:table_alias => :t2}).returns(joined_dataset)
        joined_dataset.expects(:select).with({:t1__id => :first_id, :t2__id => :second_id}).returns(joined_dataset)
        joined_dataset.expects(:filter).with(~{:t1__first_name => nil, :t2__first_name => nil}).returns(joined_dataset)
        joined_dataset.expects(:limit).with(1000, 0).returns(joined_dataset)
        joined_dataset.expects(:each).multiple_yields([{:first_id => 123, :second_id => 456}], [{:first_id => 789, :second_id => 369}])
        joined_dataset.expects(:order).with(:t1__id, :t2__id).returns(joined_dataset)
        score_set = stub("ScoreSet")
        score_set.expects(:import).with(
          [:first_id, :second_id, :score, :matcher_id],
          [[123, 456, 100, 123], [789, 369, 100, 123]]
        )

        comparator = Exact.new({
          'field_names' => ['first_name'], 'keys' => ['id', 'id'],
          'matcher_id' => 123
        })
        comparator.score(score_set, dataset_1, dataset_2)
      end

      def test_score_with_two_datasets_and_two_fields
        dataset_1 = mock("Dataset 1", :first_source_table => :people)
        dataset_2 = mock("Dataset 2", :first_source_table => :adults)
        joined_dataset = mock("Joined dataset")
        dataset_1.expects(:from).with({:people => :t1}).returns(dataset_1)
        dataset_1.expects(:join).with(:adults, [{:t2__first_name => :t1__first_name, :t2__last_name => :t1__last_name}], {:table_alias => :t2}).returns(joined_dataset)
        joined_dataset.expects(:select).with({:t1__id => :first_id, :t2__id => :second_id}).returns(joined_dataset)
        joined_dataset.expects(:filter).with(~{:t1__first_name => nil, :t2__first_name => nil}, ~{:t1__last_name => nil, :t2__last_name => nil}).returns(joined_dataset)
        joined_dataset.expects(:limit).with(1000, 0).returns(joined_dataset)
        joined_dataset.expects(:each).multiple_yields([{:first_id => 123, :second_id => 456}], [{:first_id => 789, :second_id => 369}])
        joined_dataset.expects(:order).with(:t1__id, :t2__id).returns(joined_dataset)
        score_set = stub("ScoreSet")
        score_set.expects(:import).with(
          [:first_id, :second_id, :score, :matcher_id],
          [[123, 456, 100, 123], [789, 369, 100, 123]]
        )

        comparator = Exact.new({
          'field_names' => ['first_name', 'last_name'], 'keys' => ['id', 'id'],
          'matcher_id' => 123
        })
        comparator.score(score_set, dataset_1, dataset_2)
      end
    end
  end
end
