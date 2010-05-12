module Coupler
  class Runner
    def initialize
      if !Coupler::Server.instance.is_running?
        @stop_server = true
        Coupler::Server.instance.start
      end

      if !Coupler::Scheduler.instance.is_started?
        @stop_scheduler = true
        Coupler::Scheduler.instance.start
      end

      Coupler::Database.instance.migrate!
      Coupler::Base.run! { |_| shutdown }
    end

    def shutdown
      if @stop_scheduler
        Coupler::Scheduler.instance.shutdown
      end

      if @stop_server
        Coupler::Server.instance.shutdown
      end
    end
  end
end
