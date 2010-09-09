require File.dirname(__FILE__) + '/../../helper'

module Coupler
  module Models
    class TestJob < Test::Unit::TestCase
      def test_sequel_model
        assert_equal ::Sequel::Model, Job.superclass
        assert_equal :jobs, Job.table_name
      end

      def test_belongs_to_resource
        assert_respond_to Job.new, :resource
      end

      def test_belongs_to_scenario
        assert_respond_to Job.new, :scenario
      end

      def test_percent_completed
        job = Factory(:resource_job, :total => 200, :completed => 54)
        assert_equal 27, job.percent_completed
        job.total = 0
        assert_equal 0, job.percent_completed
      end

      def test_execute_transform
        job = Factory(:resource_job, :resource => Factory(:resource))

        Resource.any_instance.expects(:source_dataset_count).returns(12345) # don't like doing this
        seq = sequence("update")
        job.expects(:update).with(:status => 'running', :total => 12345).in_sequence(seq)
        Resource.any_instance.expects(:transform!).in_sequence(seq)
        job.expects(:update).with(:status => 'done').in_sequence(seq)
        job.execute
      end

      def test_failed_transform_sets_failed_status
        job = Factory(:resource_job, :resource => Factory(:resource))

        Resource.any_instance.stubs(:source_dataset_count).returns(12345)
        seq = sequence("update")
        job.expects(:update).with(:status => 'running', :total => 12345).in_sequence(seq)
        Resource.any_instance.expects(:transform!).raises(RuntimeError).in_sequence(seq)
        job.expects(:update).with(:status => 'failed').in_sequence(seq)
        job.execute
      end

      def test_execute_run_scenario
        job = Factory(:scenario_job, :scenario => Factory(:scenario))

        seq = sequence("update")
        job.expects(:update).with(:status => 'running').in_sequence(seq)
        Scenario.any_instance.expects(:run!).in_sequence(seq)
        job.expects(:update).with(:status => 'done').in_sequence(seq)
        job.execute
      end

      def test_failed_run_scenario_sets_failed_status
        job = Factory(:scenario_job, :scenario => Factory(:scenario))

        seq = sequence("update")
        job.expects(:update).with(:status => 'running').in_sequence(seq)
        Scenario.any_instance.expects(:run!).raises(RuntimeError).in_sequence(seq)
        job.expects(:update).with(:status => 'failed').in_sequence(seq)
        job.execute
      end
    end
  end
end
