require File.dirname(__FILE__) + '/../../helper'

module Coupler
  class Scheduler
    class TestJobListener < Test::Unit::TestCase
      def setup
        super
        @listener = JobListener.new
      end

      def test_becomes_java
        assert_not_nil JobListener.java_class
      end

      def test_implements_quartz_job_listener
        assert JobListener.java_class.interfaces.include?(org.quartz.JobListener.java_class)
      end

      def test_getName
        assert_equal "Coupler Job Listener", @listener.getName
      end

      def test_jobToBeExecuted
        java_now = java.util.Date.new
        now = Time.at(java_now.time / 1000)
        job_data_map = mock("job data map") do
          expects(:get).with("job_id").returns(1)
        end
        job_detail = stub("job detail", :job_data_map => job_data_map)
        context = stub("context", :job_detail => job_detail, :fire_time => java_now)

        job_model = mock("job") do
          expects(:update).with({:status => "running", :started_at => now})
        end
        Models::Job.expects(:[]).with(:id => 1).returns(job_model)

        @listener.jobToBeExecuted(context)
      end

      def test_jobWasExecuted
        now = Time.now
        job_data_map = mock("job data map") do
          expects(:get).with("job_id").returns(1)
        end
        job_detail = stub("job detail", :job_data_map => job_data_map)
        context = stub("context", :job_detail => job_detail)
        exception = stub("job execution exception")

        job_model = mock("job") do
          expects(:update).with({:status => "done", :completed_at => now})
        end
        Models::Job.expects(:[]).with(:id => 1).returns(job_model)

        Timecop.freeze(now) do
          @listener.jobWasExecuted(context, exception)
        end
      end
    end
  end
end
