module Coupler
  module Extensions
    module Jobs
      def self.registered(app)
        app.get "/jobs" do
          @jobs = Models::Job.order("id DESC")
          erb 'jobs/index'.to_sym
        end

        app.get "/jobs/count" do
          content_type :json
          [200, [Models::Job.filter(:completed_at => nil).count.to_json]]
        end

        app.get "/jobs/:id/progress" do
          content_type :text
          @job = Models::Job[:id => params[:id]]
          [200, [{ :completed => @job.completed, :total => @job.total }.to_json]]
        end
      end
    end
  end
end
