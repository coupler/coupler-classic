module Coupler
  class Runner
    def initialize(argv = ARGV, options = {}, &block)
      @msg_proc = block
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

      say "Starting up Coupler..."

      say "Migrating database..."
      Coupler::Database.migrate!

      say "Starting scheduler..."
      Coupler::Scheduler.instance.start

      say "Starting web server..."
      settings = Coupler::Base.settings
      success = false
      begin
        @server = Rack::Server.new({
          :host => settings.bind, :port => settings.port,
          :environment => settings.environment, :root => settings.root,
          :app => Coupler::Base, :server => 'mizuno'
        })
        @web_thread = Thread.new do
          @server.start
        end
        success = true
      rescue Errno::EADDRINUSE => e
        Scheduler.instance.shutdown
        say "Can't start web server, port already in use. Aborting..."
      end

      if success
        Coupler::Base.set(:running, true)
        puts "Web server is up and running on http://#{settings.bind}:#{settings.port}"
        if !options.has_key?(:trap) || options[:trap]
          trap("INT") do
            shutdown
          end
        end

       puts <<'EOF'
                             ___
                            /\_ \
  ___    ___   __  __  _____\//\ \      __   _ __
 /'___\ / __`\/\ \/\ \/\ '__`\\ \ \   /'__`\/\`'__\
/\ \__//\ \L\ \ \ \_\ \ \ \L\ \\_\ \_/\  __/\ \ \/
\ \____\ \____/\ \____/\ \ ,__//\____\ \____\\ \_\
 \/____/\/___/  \/___/  \ \ \/ \/____/\/____/ \/_/
                         \ \_\
                          \/_/
EOF
      end
    end

    def shutdown
      say "Shutting down..."
      Scheduler.instance.shutdown
      @server.stop
    end

    def join
      @web_thread.join
    end

    private
      def say(msg)
        if @msg_proc
          @msg_proc.call(msg)
        else
          puts msg
        end
      end
  end
end
