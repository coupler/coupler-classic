require File.dirname(__FILE__) + '/../../../helper'

module Coupler
  module Models
    class Scenario
      class TestRubyRunner < Test::Unit::TestCase
        LIMIT = 10_000

        def stub_field(name)
          stub("#{name} field", :name => name)
        end

        def stub_fields_comparison(field_1, field_2 = field_1, lhs_which = 1, rhs_which = 2, operator = 'equals', &block)
          stub('comparison', {
            :lhs_type => 'field', :lhs_value => field_1, :lhs_which => lhs_which,
            :rhs_type => 'field', :rhs_value => field_2, :rhs_which => rhs_which,
            :operator => operator, :fields => [field_1, field_2]
          }, &block)
        end

        def stub_static_comparison(field, rhs_type, rhs_value, operator, lhs_which = 1, &block)
          stub('comparison', {
            :lhs_type => 'field', :lhs_value => field, :lhs_which => lhs_which,
            :rhs_type => rhs_type, :rhs_value => rhs_value,
            :operator => operator
          }, &block)
        end

        def stub_matcher(*comparisons)
          stub('matcher', :comparisons => comparisons, :id => 123)
        end

        # Create a fake dataset that returns rows specified by procs in the
        # fields argument.  This is overly complex.
        def mock_dataset(count, key, fields = [])
          dataset = mock('dataset', :count => count)
          dataset.expects(:select).with(key).returns(dataset)
          remaining = count; i = 0
          while remaining > 0
            offset = LIMIT * i
            num = LIMIT > remaining ? remaining : LIMIT
            yield_proc = eval(<<-EOF)
              Proc.new do |n|
                id = n + #{offset} + 1
                [fields.inject({key => id}) { |r, (f, p)| r[f] = p.call(id); r }, n]
              end
            EOF
            set = mock("dataset: #{offset} to #{offset + num}")
            set.expects(:each_with_index).yields_block_result(num, &yield_proc)
            dataset.expects(:limit).with(LIMIT, offset).returns(set)
            remaining -= LIMIT; i += 1
          end
          dataset
        end

        def mock_resource(key, dataset)
          mock('resource', :primary_key_name => key.to_s) do
            expects(:final_dataset).yields(dataset)
          end
        end

        def mock_scenario(resource, matcher)
          mock('scenario', {
            :matchers => [matcher],
            :resource_1 => resource,
          })
        end

        def setup
          super
          @score_set = mock('score set')
          @buffer = mock('buffer', :flush => nil)
          RowBuffer.expects(:new).with([:first_id, :second_id, :score, :matcher_id, :transitive], @score_set).returns(@buffer)
        end

        def test_self_linkage_with_one_comparison
          primary_key = :id
          dataset = mock_dataset(10500, primary_key, [
            [:ssn, lambda { |id| "1234567%02d" % ((id-1) / 350) }]
          ])
          resource = mock_resource(primary_key, dataset)

          field = stub_field('ssn')
          comparison = stub_fields_comparison(field) do
            expects(:blocking?).returns(false)
            expects(:apply).with(dataset).returns(dataset)
          end
          matcher = stub_matcher(comparison)

          score_count = 0
          mutex = Mutex.new
          @buffer.expects(:add).at_least(1).with do |row|
            mutex.synchronize do
              score_count += 1
              first_id, second_id, score, matcher_id, transitive = row
              assert_equal (first_id - 1) / 350, (second_id - 1) / 350, "##{first_id} should not have matched ##{second_id}"
              assert_equal 100, score
              assert_equal 123, matcher_id
              assert transitive
              #puts "%05d %05d" % [first_id, second_id]
            end
            true
          end

          scenario = mock_scenario(resource, matcher)

          runner = RubyRunner.new(scenario)
          runner.run(@score_set)

          assert_equal 10470, score_count
        end

        #def test_self_linkage_with_two_comparisons
          #primary_key = :id
          #field_1 = stub_field('ssn')
          #comparison_1 = stub_fields_comparison(field_1)
          #field_2 = stub_field('dob')
          #comparison_2 = stub_fields_comparison(field_2)
          #matcher = stub_matcher(comparison_1, comparison_2)
          #dataset = mock_dataset(10500, primary_key, [
            #[:ssn, lambda { |id| "1234567%02d" % ((id-1) / 350) }],
            #[:dob, lambda { |id| "2000-01-%02d" % ((id-1) / 525) }]
          #])
          #resource = mock_resource(primary_key, dataset)

          #score_count = 0
          #mutex = Mutex.new
          #@buffer.expects(:add).at_least(1).with do |row|
            #mutex.synchronize do
              #score_count += 1
              #first_id, second_id, score, matcher_id, transitive = row
              #assert_equal (first_id - 1) / 350, (second_id - 1) / 350, "##{first_id} should not have matched ##{second_id}"
              #assert_equal (first_id - 1) / 525, (second_id - 1) / 525, "##{first_id} should not have matched ##{second_id}"
              #assert_equal 100, score
              #assert_equal 123, matcher_id
              #assert transitive
              ##puts "%05d %05d" % [first_id, second_id]
            #end
            #true
          #end

          #scenario = mock_scenario(resource, matcher)

          #runner = RubyRunner.new(scenario)
          #runner.run(@score_set)

          #assert_equal 10460, score_count
        #end

        #def test_self_linkage_with_cross_match
          #primary_key = :id
          #field_1 = stub_field('foo')
          #field_2 = stub_field('bar')
          #comparison = stub_fields_comparison(field_1, field_2)
          #matcher = stub_matcher(comparison)
          #dataset = mock_dataset(1000, primary_key, [
            #[:foo, lambda { |id| (id-1) / 125 }],
            #[:bar, lambda { |id| (id-1) / 100 }]
          #])
          #resource = mock_resource(primary_key, dataset)

          #score_count = 0
          #mutex = Mutex.new
          #@buffer.expects(:add).at_least(1).with do |row|
            #mutex.synchronize do
              #score_count += 1
              #first_id, second_id, score, matcher_id, transitive = row
              #assert_equal (first_id - 1) / 125, (second_id - 1) / 100, "##{first_id} should not have matched ##{second_id}"
              #assert_equal 100, score
              #assert_equal 123, matcher_id
              #assert transitive
              ##puts "%05d %05d" % [first_id, second_id]
            #end
            #true
          #end

          #scenario = mock_scenario(resource, matcher)

          #runner = RubyRunner.new(scenario)
          #runner.run(@score_set)

          #assert_equal 246, score_count
        #end

        #def test_self_linkage_with_blocking
          #primary_key = :id
          #field_1 = stub_field('age')
          #field_2 = stub_field('height')
          #comparison_1 = stub_fields_comparison(field_1)
          #comparison_2 = stub_static_comparison(field_1, 'integer', 19, 'greater_than') do
            #expects(:filter).returns(:age > 19)
          #end
          #comparison_3 = stub_static_comparison(field_2, 'integer', 150, 'equals') do
            #expects(:filter).returns({:height => 150})
          #end
          #matcher = stub_matcher(comparison_1, comparison_2, comparison_3)
          #dataset = mock_dataset(100, primary_key, [
            #[:age, lambda { |_| 20 + rand(50) }]
          #], [:age > 19, {:height => 150}])
          #resource = mock_resource(primary_key, dataset)
          #scenario = mock_scenario(resource, matcher)

          #@buffer.stubs(:add)
          #runner = RubyRunner.new(scenario)
          #runner.run(@score_set)
        #end

        #def test_self_linkage_with_same_row_matching
          #primary_key = :id
          #field_1 = stub_field('foo')
          #field_2 = stub_field('bar')
          #comparison_1 = stub_fields_comparison(field_1)
          #comparison_2 = stub_fields_comparison(field_1, field_2, 1, 1) do
            #expects(:filter).returns({:foo => :bar})
          #end
          #matcher = stub_matcher(comparison_1, comparison_2)
          #dataset = mock_dataset(100, primary_key, [
            #[:foo, lambda { |_| rand(100) }]
          #], [:age > 19, {:height => 150}])
          #resource = mock_resource(primary_key, dataset)
          #scenario = mock_scenario(resource, matcher)

          #@buffer.stubs(:add)
          #runner = RubyRunner.new(scenario)
          #runner.run(@score_set)
        #end

        #def test_does_not_select_primary_key_twice
        #end
      end
    end
  end
end
