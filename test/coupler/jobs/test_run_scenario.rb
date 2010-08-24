require File.dirname(__FILE__) + '/../../helper'

module Coupler
  module Jobs
    class TestRunScenario < Test::Unit::TestCase
      def test_becomes_java
        assert_not_nil RunScenario.java_class
      end

      def test_implements_quartz_job
        assert RunScenario.java_class.interfaces.include?(org.quartz.Job.java_class)
      end

      def test_execute
        job_data_map = mock("job data map")
        job_data_map.expects(:get).with("scenario_id").returns(1)
        job_detail = stub("job detail", :job_data_map => job_data_map)
        context = stub("context", :job_detail => job_detail)

        scenario = mock("scenario", :run! => nil)
        Models::Scenario.expects(:[]).with(:id => 1).returns(scenario)

        job = RunScenario.new
        job.execute(context)
      end

      def test_throws_job_execution_exception
        job_data_map = stub("job data map", :get => 1)
        job_detail = stub("job detail", :job_data_map => job_data_map)
        context = stub("context", :job_detail => job_detail)

        scenario = stub("scenario") do
          stubs(:run!).raises(Exception.new("hey"))
        end
        Models::Scenario.stubs(:[]).returns(scenario)

        job = RunScenario.new
        begin
          job.execute(context)
        rescue org.quartz.JobExecutionException => exception
        end
        assert_not_nil exception
      end
    end
  end
end
