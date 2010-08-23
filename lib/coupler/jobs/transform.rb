module Coupler
  module Jobs
    class Transform
      include org.quartz.Job
      def execute(context)
        data_map = context.job_detail.job_data_map
        job_id = data_map.get("job_id")
        job_ds = Models::Job.filter(:id => job_id)
        resource_id = data_map.get("resource_id")
        resource = Models::Resource[:id => resource_id]
        resource.source_dataset { |s_ds| job_ds.update(:total => s_ds.count) }
        resource.transform! { |n| job_ds.update(:completed => :completed + n) }
      end
      add_method_signature("execute", [java.lang.Void::TYPE, org.quartz.JobExecutionContext])
    end
    Transform.become_java!
  end
end
