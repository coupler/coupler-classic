module Coupler
  module Jobs
    class Transform
      include org.quartz.Job
      def execute(context)
        resource_id = context.job_detail.job_data_map.get("resource_id")
        resource = Models::Resource[:id => resource_id]
        resource.transform!
      end
      add_method_signature("execute", [java.lang.Void::TYPE, org.quartz.JobExecutionContext])
    end
    Transform.become_java!
  end
end
