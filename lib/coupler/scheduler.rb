java_import org.quartz.impl.StdSchedulerFactory;
java_import org.quartz.JobDetail;
java_import org.quartz.SimpleTrigger;

module Coupler
  class Scheduler < Delegator
    include Singleton

    def initialize
      @scheduler = StdSchedulerFactory.default_scheduler
      @listener = Scheduler::JobListener.new
      @scheduler.add_global_job_listener(@listener)
      super(@scheduler)
    end

    def __getobj__
      @scheduler
    end

    def schedule_transform_job(resource)
      job_model = Models::Job.create({
        :name => "transform",
        :resource => resource,
        :status => "scheduled"
      })
      resource_id = resource[:id]
      job_detail = JobDetail.new("transform_resource_#{resource_id}", "coupler", Jobs::Transform.java_class)
      job_detail.job_data_map.put(java.lang.String.new("resource_id"), resource_id)
      job_detail.job_data_map.put(java.lang.String.new("job_id"), job_model[:id])
      trigger = SimpleTrigger.new("transform_resource_#{resource_id}_trigger", "coupler")
      @scheduler.schedule_job(job_detail, trigger)
    end

    def schedule_run_scenario_job(scenario)
      job_model = Models::Job.create({
        :name => "run_scenario",
        :scenario => scenario,
        :status => "scheduled"
      })
      scenario_id = scenario[:id]
      job_detail = JobDetail.new("run_scenario_#{scenario_id}", "coupler", Jobs::RunScenario.java_class)
      job_detail.job_data_map.put(java.lang.String.new("scenario_id"), scenario_id)
      job_detail.job_data_map.put(java.lang.String.new("job_id"), job_model[:id])
      trigger = SimpleTrigger.new("run_scenario_#{scenario_id}_trigger", "coupler")
      @scheduler.schedule_job(job_detail, trigger)
    end
  end
end

require File.join(File.dirname(__FILE__), "scheduler", "job_listener")
