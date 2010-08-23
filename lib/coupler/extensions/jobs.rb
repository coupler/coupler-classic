module Coupler
  module Extensions
    module Jobs
      def self.registered(app)
        app.get "/jobs" do
          @jobs = Models::Job.order("id DESC")
          erb 'jobs/index'.to_sym
        end

        app.get "/jobs/count" do
          Models::Job.filter(:completed_at => nil).count.to_s
        end

        app.get "/jobs/:id/progress" do
          @job = Models::Job[:id => params[:id]]
          @job.progress.to_s
        end
      end
    end
  end
end
