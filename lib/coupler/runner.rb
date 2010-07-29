module Coupler
  class Runner
    def initialize(argv = ARGV)
      OptionParser.new do |opts|
        opts.on("-p", "--port PORT", "Web server port") do |port|
          Base.set(:port, port.to_i)
        end
        opts.on("-d", "--dport PORT", "Database server port") do |port|
          Config.set(:database, :port, port.to_i)
        end
        opts.on("--dir DIR", "Directory to use for Coupler's data") do |dir|
          Config.set(:data_path, dir)
        end
        opts.on("-e", "--environment ENVIRONMENT", "Set the environment") do |env|
          case env
          when "production", "development", "test"
            Base.set(:environment, env.to_sym)
          else
            raise "Invalid environment (must be production, development, or test)"
          end
        end
      end.parse!(argv)

      if !Server.instance.is_running?
        @stop_server = true
        Server.instance.start
      end

      if !Scheduler.instance.is_started?
        @stop_scheduler = true
        Scheduler.instance.start
      end

      Database.instance.migrate!
      Base.run! { |_| shutdown }
    end

    def shutdown
      if @stop_scheduler
        Scheduler.instance.shutdown
      end

      if @stop_server
        Server.instance.shutdown
      end
    end
  end
end
