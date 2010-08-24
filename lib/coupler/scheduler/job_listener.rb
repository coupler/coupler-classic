module Coupler
  class Scheduler
    class JobListener
      include org.quartz.JobListener

      def getName
        "Coupler Job Listener"
      end
      add_method_signature("getName", [java.lang.String])

      def jobToBeExecuted(context)
        job_id = context.job_detail.job_data_map.get("job_id")
        job = Models::Job[:id => job_id]
        job.update(:status => "running", :started_at => Time.at(context.fire_time.time / 1000))
      end
      add_method_signature("jobToBeExecuted", [java.lang.Void::TYPE, org.quartz.JobExecutionContext])

      def jobExecutionVetoed(context)
        # no-op
      end
      add_method_signature("jobExecutionVetoed", [java.lang.Void::TYPE, org.quartz.JobExecutionContext])

      def jobWasExecuted(context, exception)
        job_id = context.job_detail.job_data_map.get("job_id")
        job = Models::Job[:id => job_id]
        job.update(:status => exception ? "failed" : "done", :completed_at => Time.now)
      end
      add_method_signature("jobWasExecuted", [java.lang.Void::TYPE, org.quartz.JobExecutionContext, org.quartz.JobExecutionException])
    end
    JobListener.become_java!
  end
end
