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

        now = Time.now
        Resource.any_instance.expects(:source_dataset_count).returns(12345) # don't like doing this
        seq = sequence("update")
        job.expects(:update).with(:status => 'running', :total => 12345, :started_at => now).in_sequence(seq)
        Resource.any_instance.expects(:transform!).in_sequence(seq)
        job.expects(:update).with(:status => 'done', :completed_at => now).in_sequence(seq)

        Timecop.freeze(now) { job.execute }
      end

      def test_failed_transform_sets_failed_status
        job = Factory(:resource_job, :resource => Factory(:resource))

        now = Time.now
        Resource.any_instance.stubs(:source_dataset_count).returns(12345)
        seq = sequence("update")
        job.expects(:update).with(:status => 'running', :total => 12345, :started_at => now).in_sequence(seq)
        fake_exception_klass = Class.new(Exception)
        Resource.any_instance.expects(:transform!).raises(fake_exception_klass.new).in_sequence(seq)
        job.expects(:update).with(:status => 'failed', :completed_at => now).in_sequence(seq)

        Timecop.freeze(now) do
          begin
            job.execute
          rescue fake_exception_klass
          end
        end
      end

      def test_execute_run_scenario
        job = Factory(:scenario_job, :scenario => Factory(:scenario))

        now = Time.now
        seq = sequence("update")
        job.expects(:update).with(:status => 'running', :started_at => now).in_sequence(seq)
        Scenario.any_instance.expects(:run!).in_sequence(seq)
        job.expects(:update).with(:status => 'done', :completed_at => now).in_sequence(seq)

        Timecop.freeze(now) { job.execute }
      end

      def test_failed_run_scenario_sets_failed_status
        job = Factory(:scenario_job, :scenario => Factory(:scenario))

        now = Time.now
        seq = sequence("update")
        job.expects(:update).with(:status => 'running', :started_at => now).in_sequence(seq)
        fake_exception_klass = Class.new(Exception)
        Scenario.any_instance.expects(:run!).raises(fake_exception_klass.new).in_sequence(seq)
        job.expects(:update).with(:status => 'failed', :completed_at => now).in_sequence(seq)

        Timecop.freeze(now) do
          begin
            job.execute
          rescue fake_exception_klass
          end
        end
      end

      def test_recently_accessed
        now = Time.now
        job_1 = job_2 = job_3 = job_4 = nil
        Timecop.freeze(now - 3) { job_1 = Factory(:scenario_job, :scenario => Factory(:scenario)) }
        Timecop.freeze(now - 2) { job_2 = Factory(:scenario_job, :scenario => Factory(:scenario)) }
        Timecop.freeze(now - 1) { job_3 = Factory(:scenario_job, :scenario => Factory(:scenario)) }
        Timecop.freeze(now)     { job_4 = Factory(:scenario_job, :scenario => Factory(:scenario)) }
        assert_equal [job_4, job_3, job_2], Job.recently_accessed
      end
    end
  end
end
