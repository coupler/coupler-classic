require File.dirname(__FILE__) + "/../helper"

module Coupler
  class TestScheduler < ActiveSupport::TestCase
    def setup
      @java_scheduler = stub("java scheduler", :start => nil, :shutdown => nil)
      StdSchedulerFactory.stubs(:default_scheduler).returns(@java_scheduler)
      Singleton.__init__(Scheduler)
    end

    def test_gets_default_scheduler
      StdSchedulerFactory.expects(:default_scheduler).returns(@java_scheduler)
      Scheduler.instance
    end

    def test_delegation
      @java_scheduler.expects(:roflsauce)
      scheduler = Scheduler.instance
      scheduler.roflsauce
    end

    def test_schedule_transform_job
      resource = stub("resource", :slug => "pants") do
        stubs(:[]).with(:id).returns(123)
      end
      scheduler = Scheduler.instance
      @java_scheduler.expects(:schedule_job) do |job, trigger|
        assert_equal "transform_pants", job.name
        assert_equal "coupler", job.group
        assert_equal Jobs::Transform.java_class, job.job_class
        assert_equal 123, job.job_data_map.get("resource_id")

        assert_equal "transform_pants_trigger", trigger.name
        assert_equal "coupler", trigger.group

        true
      end

      scheduler.schedule_transform_job(resource)
    end

    def test_schedule_run_scenario_job
      scenario = stub("scenario", :slug => "pants") do
        stubs(:[]).with(:id).returns(123)
      end
      scheduler = Scheduler.instance
      @java_scheduler.expects(:schedule_job) do |job, trigger|
        assert_equal "run_scenario_pants", job.name
        assert_equal "coupler", job.group
        assert_equal Jobs::RunScenario.java_class, job.job_class
        assert_equal 123, job.job_data_map.get("scenario_id")

        assert_equal "run_scenario_pants_trigger", trigger.name
        assert_equal "coupler", trigger.group

        true
      end

      scheduler.schedule_run_scenario_job(scenario)
    end
  end
end
