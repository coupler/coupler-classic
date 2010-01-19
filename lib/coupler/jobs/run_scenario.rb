module Coupler
  module Jobs
    class RunScenario
      include org.quartz.Job
      def execute(context)
        scenario_id = context.job_detail.job_data_map.get("scenario_id")
        scenario = Models::Scenario[:id => scenario_id]
        scenario.run!
      end
      add_method_signature("execute", [java.lang.Void::TYPE, org.quartz.JobExecutionContext])
    end
    RunScenario.become_java!
  end
end
