require File.dirname(__FILE__) + '/../../helper'

module Coupler
  module Models
    class TestResult < Test::Unit::TestCase
      class << self
        def startup
          super
          load_table_set(:basic_cross_linkage)
          load_table_set(:basic_self_linkage)
        end

        def shutdown
          unload_table_set(:basic_cross_linkage)
          unload_table_set(:basic_self_linkage)
          super
        end
      end

      def setup
        super
        @project = Factory(:project)
        @resource = Factory(:resource, :database_name => 'coupler_test_data', :table_name => 'records', :project => @project)
      end

      def test_sequel_model
        assert_equal ::Sequel::Model, Result.superclass
        assert_equal :results, Result.table_name
      end

      def test_many_to_one_scenario
        assert_respond_to Result.new, :scenario
      end

      def test_sets_scenario_version
        scenario = Factory(:scenario, :resource_1 => @resource, :project => @project)
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
        scenario = Factory(:scenario, :name => "Bar Scenario", :project => @project)
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

      def test_groups_table_name
        scenario = Factory(:scenario)
        matcher = Factory(:matcher, :scenario => scenario)
        scenario.run!
        result = scenario.results_dataset.first
        assert_equal :groups_1, result.groups_table_name
      end

      def test_groups_records_table_name
        scenario = Factory(:scenario)
        matcher = Factory(:matcher, :scenario => scenario)
        scenario.run!
        result = scenario.results_dataset.first
        assert_equal :groups_records_1, result.groups_records_table_name
      end

      def test_default_csv_export_self_linkage
        resource = Factory(:resource, :database_name => 'coupler_test_data', :table_name => 'basic_self_linkage', :project => @project)
        scenario = Factory(:scenario, :resource_1 => resource, :project => @project)
        matcher = Factory(:matcher, {
          :scenario => scenario,
          :comparisons_attributes => [{
            'lhs_type' => 'field', 'raw_lhs_value' => resource.fields_dataset[:name => 'foo'].id, 'lhs_which' => 1,
            'rhs_type' => 'field', 'raw_rhs_value' => resource.fields_dataset[:name => 'foo'].id, 'rhs_which' => 2,
            'operator' => 'equals'
          }]
        })
        scenario.run!
        result = scenario.results_dataset.first
        csv = result.to_csv

        # FIXME: add some actual csv tests you lazy bastard
      end

      def test_default_csv_export_cross_linkage
        scenario = Factory(:scenario, :resource_1 => @resource, :project => @project)
        matcher = Factory(:matcher, {
          :scenario => scenario,
          :comparisons_attributes => [{
            'lhs_type' => 'field', 'raw_lhs_value' => @resource.fields_dataset[:name => 'uno_col'].id, 'lhs_which' => 1,
            'rhs_type' => 'field', 'raw_rhs_value' => @resource.fields_dataset[:name => 'dos_col'].id, 'rhs_which' => 2,
            'operator' => 'equals'
          }]
        })
        scenario.run!
        result = scenario.results_dataset.first
        csv = result.to_csv

        # FIXME: add some actual csv tests you lazy bastard
      end
    end
  end
end
