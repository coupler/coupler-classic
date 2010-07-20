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
    end
  end
end
