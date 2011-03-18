module Coupler
  class Runner
    def initialize(argv = ARGV)
      irb = false
      OptionParser.new do |opts|
        opts.on("-p", "--port PORT", "Web server port") do |port|
          Base.set(:port, port.to_i)
        end
        opts.on("--dir DIR", "Directory to use for Coupler's data") do |dir|
          Base.set(:data_path, dir)
        end
        opts.on("-e", "--environment ENVIRONMENT", "Set the environment") do |env|
          case env
          when "production", "development", "test"
            Base.set(:environment, env.to_sym)
          else
            raise "Invalid environment (must be production, development, or test)"
          end
        end
        opts.on('-i', '--interactive', "Run an IRB session") do
          irb = true
        end
      end.parse!(argv)

      Scheduler.instance.start
      Database.instance.migrate!

      if irb
        at_exit { shutdown }
        require "irb"
        IRB.start
      else
        Base.run! { |_| shutdown }
      end
    end

    def shutdown
      Scheduler.instance.shutdown
    end
  end
end
