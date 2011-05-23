module Coupler
  class Scheduler
    include Singleton

    def initialize
      super
      @mutex = Mutex.new
    end

    def schedule_transform_job(resource)
      Models::Job.create({
        :name => "transform",
        :resource => resource,
        :status => "scheduled"
      })
    end

    def schedule_run_scenario_job(scenario)
      Models::Job.create({
        :name => "run_scenario",
        :scenario => scenario,
        :status => "scheduled"
      })
    end

    def schedule_import_job(import)
      Models::Job.create({
        :name => "import",
        :import => import,
        :status => "scheduled"
      })
    end

    def run_jobs
      @mutex.synchronize do
        count = Models::Job.filter(:status => 'running').count
        if count == 0
          job = Models::Job.filter(:status => 'scheduled').order(:created_at).first
          Thread.new(job) { |j| j.execute } if job
        end
      end
    end

    def start
      if !is_started?
        @loop = Thread.new do
          loop do
            sleep 10
            run_jobs
          end
        end
      end
    end

    def shutdown
      @loop.exit
      @loop = nil
    end

    def is_started?
      !@loop.nil?
    end
  end
end
