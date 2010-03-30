module Coupler
  module Extensions
    module Jobs
      def self.registered(app)
        app.get "/jobs" do
          @jobs = Models::Job.order(:id)
          erb 'jobs/index'.to_sym
        end

        app.get "/jobs/count" do
          Coupler::Models::Job.filter(:completed_at => nil).count.to_s
        end
      end
    end
  end
end
