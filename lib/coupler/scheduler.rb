java_import org.quartz.impl.StdSchedulerFactory;
java_import org.quartz.JobDetail;
java_import org.quartz.SimpleTrigger;

module Coupler
  class Scheduler < Delegator
    include Singleton

    def initialize
      @scheduler = StdSchedulerFactory.default_scheduler
    end

    def __getobj__
      @scheduler
    end

    def schedule_transform_job(resource)
      job_detail = JobDetail.new("transform_#{resource.slug}", "coupler", Jobs::Transform.java_class)
      job_detail.job_data_map.put(java.lang.String.new("resource_id"), resource[:id])
      trigger = SimpleTrigger.new("transform_#{resource.slug}_trigger", "coupler")
      @scheduler.schedule_job(job_detail, trigger)
    end

    def schedule_run_scenario_job(scenario)
      job_detail = JobDetail.new("run_scenario_#{scenario.slug}", "coupler", Jobs::RunScenario.java_class)
      job_detail.job_data_map.put(java.lang.String.new("scenario_id"), scenario[:id])
      trigger = SimpleTrigger.new("run_scenario_#{scenario.slug}_trigger", "coupler")
      @scheduler.schedule_job(job_detail, trigger)
    end
  end
end
