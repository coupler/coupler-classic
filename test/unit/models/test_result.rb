require 'helper'

module Coupler
  module Models
    class TestResult < Coupler::Test::UnitTest
      def new_result(attribs = {})
        values = {
          :scenario => @scenario
        }.update(attribs)
        r = Result.new(values)
        r.stubs(:scenario_dataset).returns(stub({:all => [values[:scenario]]}))
        r
      end

      def setup
        super
        @scenario = stub('scenario', :id => 100, :pk => 100, :associations => {}, :version => 42)
      end

      test "sequel model" do
        assert_equal ::Sequel::Model, Result.superclass
        assert_equal :results, Result.table_name
      end

      test "many to one scenario" do
        assert_respond_to Result.new, :scenario
      end

      test "sets scenario version" do
        result = new_result.save!
        assert_equal 42, result.scenario_version
      end

      test "snapshot gets originating models" do
        time = Time.now - 50
        @scenario.stubs({
          :updated_at => time, :project_id => 123,
          :resource_1_id => 456, :resource_2_id => 789
        })
        result = new_result.save!

        project = stub('project')
        resource_1 = stub('resource 1')
        resource_2 = stub('resource 2')
        Scenario.expects(:as_of_version).with(100, 42).returns(@scenario)
        Project.expects(:as_of_time).with(123, time).returns(project)
        Resource.expects(:as_of_time).with(456, time).returns(resource_1)
        Resource.expects(:as_of_time).with(789, time).returns(resource_2)

        expected = {
          :project => project, :scenario => @scenario,
          :resource_1 => resource_1, :resource_2 => resource_2
        }
        assert_equal expected, result.snapshot
      end

      test "groups dataset" do
        result = new_result(:run_number => 5).save!
        ds = mock('dataset')
        @scenario.expects(:local_database).yields(mock('database') {
          expects(:[]).with(:groups_5).returns(ds)
        })
        result.groups_dataset do |actual|
          assert_equal ds, actual
        end
      end

      test "groups records dataset" do
        result = new_result(:run_number => 5).save!
        ds = mock('dataset')
        @scenario.expects(:local_database).yields(mock('database') {
          expects(:[]).with(:groups_records_5).returns(ds)
        })
        result.groups_records_dataset do |actual|
          assert_equal ds, actual
        end
      end

      test "groups table name" do
        result = new_result(:run_number => 5).save!
        assert_equal :groups_5, result.groups_table_name
      end

      test "groups records table name" do
        result = new_result(:run_number => 5).save!
        assert_equal :groups_records_5, result.groups_records_table_name
      end
    end
  end
end
