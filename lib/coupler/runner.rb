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

      trap("INT") { shutdown }

      Coupler::Database.instance.migrate!
      Coupler::Base.run!
    end

    def shutdown
      Coupler::Scheduler.instance.shutdown
      Coupler::Server.instance.shutdown
    end
  end
end
