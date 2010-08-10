require File.dirname(__FILE__) + "/../helper"

module Coupler
  class TestScheduler < Test::Unit::TestCase
    def setup
      super
      @java_scheduler = stub("java scheduler", :start => nil, :shutdown => nil, :add_global_job_listener => nil)
      StdSchedulerFactory.stubs(:default_scheduler).returns(@java_scheduler)
      Singleton.__init__(Scheduler)
    end

    def test_gets_default_scheduler
      StdSchedulerFactory.expects(:default_scheduler).returns(@java_scheduler)
      Scheduler.instance
    end

    def test_attaches_job_listener
      listener = stub("job listener")
      Scheduler::JobListener.expects(:new).returns(listener)
      @java_scheduler.expects(:add_global_job_listener).with(listener)
      Scheduler.instance
    end

    def test_delegation
      @java_scheduler.expects(:roflsauce)
      scheduler = Scheduler.instance
      scheduler.roflsauce
    end

    def test_schedule_transform_job
      resource = stub("resource") do
        stubs(:[]).with(:id).returns(123)
      end
      job_model = stub("job model") do
        stubs(:[]).with(:id).returns(456)
      end
      Models::Job.expects(:create).with({
        :name => "transform",
        :resource => resource,
        :status => "scheduled"
      }).returns(job_model)

      scheduler = Scheduler.instance
      @java_scheduler.expects(:schedule_job).with do |job_detail, trigger|
        assert_equal "transform_resource_123", job_detail.name
        assert_equal "coupler", job_detail.group
        assert_equal Jobs::Transform.java_class, job_detail.job_class
        assert_equal 123, job_detail.job_data_map.get("resource_id")
        assert_equal 456, job_detail.job_data_map.get("job_id")

        assert_equal "transform_resource_123_trigger", trigger.name
        assert_equal "coupler", trigger.group

        true
      end

      scheduler.schedule_transform_job(resource)
    end

    def test_schedule_run_scenario_job
      scenario = stub("scenario") do
        stubs(:[]).with(:id).returns(123)
      end
      job_model = stub("job model") do
        stubs(:[]).with(:id).returns(456)
      end
      Models::Job.expects(:create).with({
        :name => "run_scenario",
        :scenario => scenario,
        :status => "scheduled"
      }).returns(job_model)

      scheduler = Scheduler.instance
      @java_scheduler.expects(:schedule_job).with do |job_detail, trigger|
        assert_equal "run_scenario_123", job_detail.name
        assert_equal "coupler", job_detail.group
        assert_equal Jobs::RunScenario.java_class, job_detail.job_class
        assert_equal 123, job_detail.job_data_map.get("scenario_id")
        assert_equal 456, job_detail.job_data_map.get("job_id")

        assert_equal "run_scenario_123_trigger", trigger.name
        assert_equal "coupler", trigger.group

        true
      end

      scheduler.schedule_run_scenario_job(scenario)
    end
  end
end
