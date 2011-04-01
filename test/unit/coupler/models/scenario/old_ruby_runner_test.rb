require File.dirname(__FILE__) + '/../../../helper'

module Coupler
  module Models
    class Scenario
      class TestRubyRunner < Test::Unit::TestCase
        LIMIT = 10_000

        def stub_field(name, label = name)
          stub("#{name} field", :name => name)
        end

        def stub_fields_comparison(field_1, field_2 = field_1, lhs_which = 1, rhs_which = 2, operator = 'equals', &block)
          stub('comparison', {
            :lhs_type => 'field', :raw_lhs_value => field_1, :lhs_which => lhs_which,
            :rhs_type => 'field', :raw_rhs_value => field_2, :rhs_which => rhs_which,
            :operator => operator, :fields => [field_1, field_2]
          }, &block)
        end

        def stub_static_comparison(field, rhs_type, rhs_value, operator, lhs_which = 1, &block)
          stub('comparison', {
            :lhs_type => 'field', :raw_lhs_value => field, :lhs_which => lhs_which,
            :rhs_type => rhs_type, :raw_rhs_value => rhs_value,
            :operator => operator
          }, &block)
        end

        def stub_matcher(*comparisons)
          stub('matcher', :comparisons => comparisons, :id => 123)
        end

        # Create a fake dataset that returns rows specified by procs in the
        # fields argument.  This is overly complex.
        def mock_dataset(count, key, data = [], method = :each)
          dataset = mock('dataset', :count => count)
          dataset.expects(:select).with(key).returns(dataset)
          remaining = count; i = 0
          while remaining > 0
            offset = LIMIT * i
            num = LIMIT > remaining ? remaining : LIMIT
            set = mock("dataset: #{offset} to #{offset + num}")
            case method
            when :each
              yield_proc = eval(<<-EOF)
                Proc.new do |n|
                  id = n + #{offset} + 1
                  [data.inject({key => id}) { |r, (f, p)| r[f] = p.call(id); r }, n]
                end
              EOF
              set.expects(:each_with_index).yields_block_result(num, &yield_proc)
            when :all
              set.expects(:all).returns(data[offset...(offset + LIMIT)])
            end
            dataset.expects(:limit).with(LIMIT, offset).returns(set)
            remaining -= LIMIT; i += 1
          end
          dataset
        end

        def mock_resource(key, dataset)
          @resource_count += 1
          stub('resource', :primary_key_name => key.to_s, :id => @resource_count) do
            expects(:final_dataset).yields(dataset)
          end
        end

        def stub_scenario(matcher, resource_1, resource_2 = nil)
          stub('scenario', {
            :matchers => [matcher],
            :resources => resource_2 ? [resource_1, resource_2] : [resource_1],
            :linkage_type => resource_2 ? 'dual-linkage' : 'self-linkage'
          })
        end

        #def setup
          #super
          #@score_set = mock('score set')
          #@resource_count = 0
          #@buffer = mock('buffer', :flush => nil)
          #RowBuffer.expects(:new).with([:record_id, :resource_id, :group, :matcher_id], @score_set).returns(@buffer)
        #end

=begin
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
          groups = {}
          mutex = Mutex.new
          @buffer.expects(:add).at_least(1).with do |row|
            record_id, resource_id, group, matcher_id = row
            mutex.synchronize do
              score_count += 1
              groups[group] ||= record_id
              #puts "%05d %05d" % [record_id, group]
            end
            if groups[group] != record_id
              first_id = groups[group]
              assert_equal (first_id - 1) / 350, (record_id - 1) / 350, "Record #{first_id} shouldn't have matched record #{record_id}"
            end
            assert_equal resource.id, resource_id
            assert_equal 123, matcher_id
            true
          end
          @score_set.expects(:filter).with { |opts|
            opts[:group].is_a?(Fixnum) && opts[:matcher_id] == 123
          }.returns(@score_set)
          @score_set.expects(:update).with { |opts| opts[:group].is_a?(Fixnum) }

          scenario = stub_scenario(matcher, resource)

          runner = RubyRunner.new(scenario, @score_set)
          runner.run

          #assert_equal 10500, score_count
        end

        def test_self_linkage_with_two_comparisons
          primary_key = :id
          dataset = mock_dataset(10500, primary_key, [
            [:ssn, lambda { |id| "1234567%02d" % ((id-1) / 350) }],
            [:dob, lambda { |id| "2000-01-%02d" % ((id-1) / 525) }]
          ])
          resource = mock_resource(primary_key, dataset)

          field_1 = stub_field('ssn')
          comparison_1 = stub_fields_comparison(field_1) do
            expects(:blocking?).returns(false)
            expects(:apply).with(dataset).returns([ dataset ])
          end
          field_2 = stub_field('dob')
          comparison_2 = stub_fields_comparison(field_2) do
            expects(:blocking?).returns(false)
            expects(:apply).with(dataset).returns([ dataset ])
          end
          matcher = stub_matcher(comparison_1, comparison_2)

          score_count = 0
          groups = {}
          mutex = Mutex.new
          @buffer.expects(:add).at_least(1).with do |row|
            record_id, resource_id, group, matcher_id = row
            mutex.synchronize do
              score_count += 1
              groups[group] ||= record_id
              #puts "%05d %05d" % [record_id, group]
            end
            if groups[group] != record_id
              first_id = groups[group]
              assert_equal (first_id - 1) / 350, (record_id - 1) / 350, "##{first_id} should not have matched ##{record_id}"
              assert_equal (first_id - 1) / 525, (record_id - 1) / 525, "##{first_id} should not have matched ##{record_id}"
            end
            assert_equal resource.id, resource_id
            assert_equal 123, matcher_id
            true
          end
          @score_set.expects(:filter).with { |opts|
            opts[:group].is_a?(Fixnum) && opts[:matcher_id] == 123
          }.returns(@score_set)
          @score_set.expects(:update).with { |opts| opts[:group].is_a?(Fixnum) }

          scenario = stub_scenario(matcher, resource)

          runner = RubyRunner.new(scenario, @score_set)
          runner.run

          #assert_equal 10500, score_count
        end

        def test_self_linkage_with_cross_match
          primary_key = :id
          dataset = mock_dataset(1000, primary_key, [
            [:foo, lambda { |id| (id-1) / 125 }],
            [:bar, lambda { |id| (id-1) / 100 }]
          ])
          resource = mock_resource(primary_key, dataset)

          field_1 = stub_field('foo')
          field_2 = stub_field('bar')
          comparison = stub_fields_comparison(field_1, field_2) do
            expects(:blocking?).returns(false)
            expects(:apply).with(dataset).returns([ dataset ])
          end
          matcher = stub_matcher(comparison)

          score_count = 0
          groups = {}
          mutex = Mutex.new
          @buffer.expects(:add).at_least(1).with do |row|
            record_id, resource_id, group, matcher_id = row
            mutex.synchronize do
              score_count += 1
              groups[group] ||= record_id
              #puts "%05d %05d" % [record_id, group]
            end
            if groups[group] != record_id
              first_id = groups[group]
              assert_equal (first_id - 1) / 125, (record_id - 1) / 100, "##{first_id} should not have matched ##{record_id}"
            end
            assert_equal resource.id, resource_id
            assert_equal 123, matcher_id
            true
          end

          scenario = stub_scenario(matcher, resource)

          runner = RubyRunner.new(scenario, @score_set)
          runner.run

          #assert_equal 250, score_count
        end

        def test_self_linkage_with_blocking
          primary_key = :id
          dataset = mock_dataset(100, primary_key, [
            [:age, lambda { |_| 20 + rand(50) }]
          ])
          resource = mock_resource(primary_key, dataset)

          field_1 = stub_field('age')
          field_2 = stub_field('height')
          comparison_1 = stub_fields_comparison(field_1) do
            expects(:blocking?).returns(false)
            expects(:apply).with(dataset).returns([ dataset ])
          end
          comparison_2 = stub_static_comparison(field_1, 'integer', 19, 'greater_than') do
            expects(:blocking?).returns(true)
            expects(:apply).with(dataset).returns([ dataset ])
          end
          comparison_3 = stub_static_comparison(field_2, 'integer', 150, 'equals') do
            expects(:blocking?).returns(true)
            expects(:apply).with(dataset).returns([ dataset ])
          end
          matcher = stub_matcher(comparison_1, comparison_2, comparison_3)
          scenario = stub_scenario(matcher, resource)

          @buffer.stubs(:add)
          runner = RubyRunner.new(scenario, @score_set)
          runner.run
        end

        # Do this both ways to make sure things are behaving.  EVIL TEST LOOPING
        [false, true].each do |swap|
          define_method(:"test_dual_linkage_with_one_comparison#{swap ? '_swapped' : ''}") do
            dataset_1 = mock_dataset(100, :foo_id,
              Array.new(100) { |i| {:foo_id => i+1, :ssn => "1234567%02d" % (i / 5)} }, :all)
            resource_1 = mock_resource(:foo_id, dataset_1)

            dataset_2 = mock_dataset(200, :bar_id,
              Array.new(200) { |i| {:bar_id => i+1, :ssn => "1234567%02d" % (i / 10)} }, :all)
            resource_2 = mock_resource(:bar_id, dataset_2)

            if swap
              dataset_1, dataset_2 = dataset_2, dataset_1
              resource_1, resource_2 = resource_2, resource_1
            end

            field_1 = stub_field('ssn', "resource 1 ssn")
            field_2 = stub_field('ssn', "resource 2 ssn")
            comparison = stub_fields_comparison(field_1, field_2) do
              expects(:blocking?).returns(false)
              expects(:apply).with(dataset_1, dataset_2).returns([dataset_1, dataset_2])
            end
            matcher = stub_matcher(comparison)

            score_count = 0
            groups = {}
            mutex = Mutex.new
            @buffer.expects(:add).at_least(1).with do |row|
              record_id, resource_id, group, matcher_id = row
              mutex.synchronize do
                score_count += 1
                groups[group] ||= record_id
                #p row
                #puts "%05d %05d" % [record_id, group]
              end
              if groups[group] != record_id
                first_id = groups[group]
                if resource_id == resource_1.id
                  expected = swap ? (first_id  - 1) / 10 : (first_id  - 1) / 5
                  actual   = swap ? (record_id - 1) / 10 : (record_id - 1) / 5
                elsif resource_id == resource_2.id
                  expected = swap ? (first_id  - 1) / 10 : (first_id  - 1) /  5
                  actual   = swap ? (record_id - 1) /  5 : (record_id - 1) / 10
                else
                  flunk "resource_id was invalid"
                end
                assert_equal expected, actual, "##{record_id} should not have been in the same group as ##{first_id}"
              end
              assert_equal 123, matcher_id
              true
            end

            scenario = stub_scenario(matcher, resource_1, resource_2)

            runner = RubyRunner.new(scenario, @score_set)
            runner.run

            assert_equal 300, score_count
          end

          define_method(:"test_dual_linkage_with_one_comparison_and_large_overlapping_datasets#{swap ? '_swapped' : ''}") do
            dataset_1 = mock_dataset(10500, :foo_id,
              Array.new(10500) { |i| {:foo_id => i+1, :ssn => "1234567%02d" % (i / 350)} }, :all)
            resource_1 = mock_resource(:foo_id, dataset_1)

            dataset_2 = mock_dataset(10500, :bar_id,
              Array.new(10500) { |i| {:bar_id => i+1, :ssn => "1234567%02d" % (i / 525)} }, :all)
            resource_2 = mock_resource(:bar_id, dataset_2)

            if swap
              dataset_1, dataset_2 = dataset_2, dataset_1
              resource_1, resource_2 = resource_2, resource_1
            end

            field_1 = stub_field('ssn', "resource 1 ssn")
            field_2 = stub_field('ssn', "resource 2 ssn")
            comparison = stub_fields_comparison(field_1, field_2) do
              expects(:blocking?).returns(false)
              expects(:apply).with(dataset_1, dataset_2).returns([dataset_1, dataset_2])
            end
            matcher = stub_matcher(comparison)

            score_count = 0
            groups = {}
            mutex = Mutex.new
            @buffer.expects(:add).at_least(1).with do |row|
              record_id, resource_id, group, matcher_id = row
              mutex.synchronize do
                score_count += 1
                groups[group] ||= record_id
                #p row
                #puts "%05d %05d" % [record_id, group]
              end
              if groups[group] != record_id
                first_id = groups[group]
                if resource_id == resource_1.id
                  expected = swap ? (first_id  - 1) / 525 : (first_id  - 1) / 350
                  actual   = swap ? (record_id - 1) / 525 : (record_id - 1) / 350
                elsif resource_id == resource_2.id
                  expected = swap ? (first_id  - 1) / 525 : (first_id  - 1) / 350
                  actual   = swap ? (record_id - 1) / 350 : (record_id - 1) / 525
                else
                  flunk "resource_id was invalid"
                end
                assert_equal expected, actual, "##{record_id} should not have been in the same group as ##{first_id}"
              end
              assert_equal 123, matcher_id
              true
            end

            scenario = stub_scenario(matcher, resource_1, resource_2)

            runner = RubyRunner.new(scenario, @score_set)
            runner.run

            assert_equal 17500, score_count
          end
        end

        #def test_dual_linkage_with_one_comparison
          #dataset_1 = mock_dataset(100, :foo_id,
                                   #Array.new(100) { |i| {:id => i+1, :ssn => "1234567%02d" % (i / 5)} }, :all)
          #resource_1 = mock_resource(:foo_id, dataset_1)

          #dataset_2 = mock_dataset(200, :bar_id,
                                   #Array.new(200) { |i| {:id => i+1, :ssn => "1234567%02d" % (i / 10)} }, :all)
          #resource_2 = mock_resource(:bar_id, dataset_2)

          #field_1 = stub_field('ssn', "resource 1 ssn")
          #field_2 = stub_field('ssn', "resource 2 ssn")
          #comparison = stub_fields_comparison(field_1, field_2) do
            #expects(:blocking?).returns(false)
            #expects(:apply).with(dataset_1, dataset_2).returns([dataset_1, dataset_2])
          #end
          #matcher = stub_matcher(comparison)

          #score_count = 0
          #groups = {}
          #mutex = Mutex.new
          #@buffer.expects(:add).at_least(1).with do |row|
            #record_id, resource_id, group, matcher_id = row
            #mutex.synchronize do
              #score_count += 1
              #groups[group] ||= record_id
              ##puts "%05d %05d" % [record_id, group]
            #end
            #if groups[group] != record_id
              #first_id = groups[group]
              #if resource_id == resource_1.id
                #assert_equal (first_id - 1) / 5, (record_id - 1) / 5, "##{record_id} should not have been in the same group as ##{first_id}"
              #elsif resource_id == resource_2.id
                #assert_equal (first_id - 1) / 5, (record_id - 1) / 10, "##{record_id} should not have been in the same group as ##{first_id}"
              #else
                #flunk "resource_id was invalid"
              #end
            #end
            #assert_equal 123, matcher_id
            #true
          #end

          #scenario = stub_scenario(matcher, resource_1, resource_2)

          #runner = RubyRunner.new(scenario, @score_set)
          #runner.run

          ##assert_equal 250, score_count
        #end
=end
      end
    end
  end
end
