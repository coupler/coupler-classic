require File.dirname(__FILE__) + '/../../helper'

module Coupler
  module Models
    class TestResult < Test::Unit::TestCase
      def test_sequel_model
        assert_equal ::Sequel::Model, Result.superclass
        assert_equal :results, Result.table_name
      end

      def test_many_to_one_scenario
        assert_respond_to Result.new, :scenario
      end

      def test_sets_scenario_version
        scenario = Factory(:scenario)
        result = Factory(:result, :scenario => scenario)
        assert_equal scenario.version, result.scenario_version
      end

      def test_snapshot_gets_originating_project
        project = Factory(:project, :name => "Blah")
        resource = Factory(:resource, :project => project)
        scenario = Factory(:scenario, :project => project, :resource_1 => resource)
        result = Factory(:result, :scenario => scenario)
        project.update(:name => "Blah blah")

        assert_equal "Blah", result.snapshot[:project][:name]
      end

      def test_snapshot_gets_originating_scenario
        scenario = Factory(:scenario, :name => "Bar Scenario")
        result = Factory(:result, :scenario => scenario)
        scenario.update(:name => "Foo Scenario")

        hash = result.snapshot
        assert_equal "Bar Scenario", hash[:scenario][:name]
      end

      def test_snapshot_gets_originating_resources
        project = Factory(:project)
        resource_1 = Factory(:resource, :project => project, :name => "Uno")
        resource_2 = Factory(:resource, :project => project, :name => "Dos")
        resource_3 = Factory(:resource, :project => project, :name => "Tres")
        scenario = Factory(:scenario, :project => project, :resource_1 => resource_1, :resource_2 => resource_2)
        result = Factory(:result, :scenario => scenario)
        scenario.update(:resource_1 => resource_3)
        resource_1.update(:name => "Ichi")

        hash = result.snapshot
        assert_equal "Uno", hash[:resource_1][:name]
        assert_equal "Dos", hash[:resource_2][:name]
      end

      def test_to_csv
        pend
        project = Factory(:project)
        resource_1 = Factory(:resource, :project => project, :name => "Uno")
        resource_2 = Factory(:resource, :project => project, :name => "Dos")
        scenario = Factory(:scenario, :project => project, :resource_1 => resource_1, :resource_2 => resource_2)
        score_set_id = nil
        ScoreSet.create do |score_set|
          score_set_id = score_set.id
          score_set.insert(:first_id => 13, :second_id => 37, :score => 456, :matcher_id => 1)
          score_set.insert(:first_id => 867, :second_id => 5309, :score => 123, :matcher_id => 1)
          score_set.insert(:first_id => 867, :second_id => 5309, :score => 321, :matcher_id => 2)
        end
        result = Factory(:result, :scenario => scenario, :score_set_id => score_set_id)

        expected = [
          %w{uno_id dos_id score matcher_ids},
          %w{13 37 456 1},
          %w{867 5309 444 1,2}
        ]
        arr = FasterCSV.parse(result.to_csv)
        assert_equal expected, arr
      end

      def test_groups_dataset
        scenario = Factory(:scenario)
        matcher = Factory(:matcher, :scenario => scenario)
        scenario.run!
        result = scenario.results_dataset.first
        result.groups_dataset do |ds|
          assert_equal :groups_1, ds.first_source_alias
          assert_match /scenario_#{scenario.id}/, ds.db.uri
        end
      end

      def test_groups_records_dataset
        scenario = Factory(:scenario)
        matcher = Factory(:matcher, :scenario => scenario)
        scenario.run!
        result = scenario.results_dataset.first
        result.groups_records_dataset do |ds|
          assert_equal :groups_records_1, ds.first_source_alias
          assert_match /scenario_#{scenario.id}/, ds.db.uri
        end
      end

      def test_summary_for_simple_self_linkage
        project = Factory(:project)
        resource = Factory(:resource, :project => project)
        field = resource.fields_dataset[:name => 'first_name']
        scenario = Factory(:scenario, :project => project, :resource_1 => resource)
        matcher = Factory(:matcher, :scenario => scenario, :comparisons_attributes => [{
          'lhs_type' => 'field', 'lhs_value' => field.id, 'lhs_which' => 1,
          'rhs_type' => 'field', 'rhs_value' => field.id, 'rhs_which' => 2,
          'operator' => 'equals'
        }])
        scenario.run!
        result = scenario.results_dataset.first
        summary = result.summary
        assert_equal([["first_name", "first_name"]], summary[:fields])
        scenario.local_database do |db|
          counts = db[:groups_records_1].group_and_count(:group_id).having(:count > 1).order(:group_id).all
          assert_equal counts.length, summary[:groups].length
          summary[:groups].each_with_index do |group, i|
            assert_equal counts[i][:group_id], group[:id]
            assert_equal counts[i][:count], group[:matches].length
          end
          assert_equal counts.inject(0) { |sum, h| sum + h[:count] }, summary[:total_matches]
        end
      end
    end
  end
end
