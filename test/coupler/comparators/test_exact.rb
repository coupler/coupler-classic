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
        dataset.expects(:order).with(:first_name).returns(dataset)
        records = [
          [{:id => 5, :first_name => "Harry"}],
          [{:id => 6, :first_name => "Harry"}],
          [{:id => 3, :first_name => "Ron"}],
          [{:id => 8, :first_name => "Ron"}]
        ]
        dataset.expects(:each).multiple_yields(*records)
        score_set = stub("ScoreSet")
        score_set.expects(:insert_or_update).with(:first_id => 5, :second_id => 6, :score => 100)
        score_set.expects(:insert_or_update).with(:first_id => 3, :second_id => 8, :score => 100)

        comparator = Exact.new('field_names' => ['first_name'], 'keys' => ['id'])
        comparator.score(score_set, dataset)
      end

      def test_score_with_single_dataset_and_two_fields
        dataset = stub("Dataset")
        dataset.expects(:select).with(:id, :first_name, :last_name).returns(dataset)
        dataset.expects(:order).with(:first_name, :last_name).returns(dataset)
        records = [
          [{:id => 5, :first_name => "Harry", :last_name => "Pewterschmidt"}],
          [{:id => 6, :first_name => "Harry", :last_name => "Potter"}],
          [{:id => 3, :first_name => "Harry", :last_name => "Potter"}],
          [{:id => 8, :first_name => "Ron", :last_name => "Skywalker"}]
        ]
        dataset.expects(:each).multiple_yields(*records)
        score_set = stub("ScoreSet")
        score_set.expects(:insert_or_update).with(:first_id => 6, :second_id => 3, :score => 100)

        comparator = Exact.new('field_names' => ['first_name', 'last_name'], 'keys' => ['id'])
        comparator.score(score_set, dataset)
      end

      def test_score_with_two_datasets_and_one_field
        dataset_1 = mock("Dataset 1", :first_source_table => :people)
        dataset_2 = mock("Dataset 2", :first_source_table => :adults)
        joined_dataset = mock("Joined dataset")
        dataset_1.expects(:from).with({:people => :t1}).returns(dataset_1)
        dataset_1.expects(:join).with(:adults, {:first_name => :first_name}, {:table_alias => :t2}).returns(joined_dataset)
        joined_dataset.expects(:select).with({:t1__id => :first_id, :t2__id => :second_id}).returns(joined_dataset)
        joined_dataset.expects(:limit).with(1000, 0).returns(joined_dataset)
        joined_dataset.expects(:each).multiple_yields([{:first_id => 123, :second_id => 456}], [{:first_id => 789, :second_id => 369}])
        joined_dataset.expects(:order).with(:t1__id, :t2__id).returns(joined_dataset)
        score_set = stub("ScoreSet")
        score_set.expects(:insert_or_update).with(:first_id => 123, :second_id => 456, :score => 100)
        score_set.expects(:insert_or_update).with(:first_id => 789, :second_id => 369, :score => 100)

        comparator = Exact.new('field_names' => ['first_name'], 'keys' => ['id', 'id'])
        comparator.score(score_set, dataset_1, dataset_2)
      end

      def test_score_with_two_datasets_and_two_fields
        dataset_1 = mock("Dataset 1", :first_source_table => :people)
        dataset_2 = mock("Dataset 2", :first_source_table => :adults)
        joined_dataset = mock("Joined dataset")
        dataset_1.expects(:from).with({:people => :t1}).returns(dataset_1)
        dataset_1.expects(:join).with(:adults, {:first_name => :first_name, :last_name => :last_name}, {:table_alias => :t2}).returns(joined_dataset)
        joined_dataset.expects(:select).with({:t1__id => :first_id, :t2__id => :second_id}).returns(joined_dataset)
        joined_dataset.expects(:limit).with(1000, 0).returns(joined_dataset)
        joined_dataset.expects(:each).multiple_yields([{:first_id => 123, :second_id => 456}], [{:first_id => 789, :second_id => 369}])
        joined_dataset.expects(:order).with(:t1__id, :t2__id).returns(joined_dataset)
        score_set = stub("ScoreSet")
        score_set.expects(:insert_or_update).with(:first_id => 123, :second_id => 456, :score => 100)
        score_set.expects(:insert_or_update).with(:first_id => 789, :second_id => 369, :score => 100)

        comparator = Exact.new('field_names' => ['first_name', 'last_name'], 'keys' => ['id', 'id'])
        comparator.score(score_set, dataset_1, dataset_2)
      end

      #def test_scores_null_values_as_non_match
        #dataset_1 = stub("Dataset 1", :count => 4)
        #dataset_1.stubs({
          #:select => dataset_1, :order => dataset_1, :limit => dataset_1
        #})
        #dataset_1.stubs(:all).returns([
          #{:id => 1, :first_name => nil}, {:id => 2, :first_name => nil},
          #{:id => 3, :first_name => 'Bob'}, {:id => 4, :first_name => 'George'},
        #])

        #dataset_2 = stub("Dataset 2", :count => 4)
        #dataset_2.stubs({
          #:select => dataset_2, :order => dataset_2, :limit => dataset_2
        #})
        #dataset_2.stubs(:all).returns([
          #{:id => 1, :first_name => nil}, {:id => 2, :first_name => 'Bob'},
          #{:id => 3, :first_name => 'Fred'}, {:id => 4, :first_name => 'George'},
        #])

        #results = Hash.new { |h, k| h[k] = [] }
        #score_set = stub("ScoreSet")
        #score_set.expects(:insert_or_update).times(2).with do |hash|
          #assert_equal 100, hash[:score]
          #results[hash[:first_id]] << hash[:second_id]
        #end

        #comparator = Exact.new('field_names' => ['first_name', 'first_name'], 'keys' => ['id', 'id'])
        #comparator.score(score_set, dataset_1, dataset_2)
      #end

      #def test_null_as_nonmatch
        #comparator = Exact.new('field_name' => 'first_name')
        #assert_equal 0, comparator.score({:first_name => nil}, {:first_name => nil})
      #end
    end
  end
end
