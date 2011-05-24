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
      Coupler::Database.instance.migrate!

      say "Starting scheduler..."
      Coupler::Scheduler.instance.start

      say "Starting web server..."
      handler = Rack::Handler.get('mongrel')
      settings = Coupler::Base.settings

      # See the Rack::Handler::Mongrel.run! method
      # NOTE: I don't want to join the server immediately, which is why I'm
      #       doing this by hand.
      @web_server = Mongrel::HttpServer.new(settings.bind, settings.port, 950, 0, 60)
      @web_server.register('/', handler.new(Coupler::Base))
      success = false
      begin
        @web_thread = @web_server.run
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

#        say <<'EOF'
#                             ___
#                            /\_ \
#  ___    ___   __  __  _____\//\ \      __   _ __
# /'___\ / __`\/\ \/\ \/\ '__`\\ \ \   /'__`\/\`'__\
#/\ \__//\ \L\ \ \ \_\ \ \ \L\ \\_\ \_/\  __/\ \ \/
#\ \____\ \____/\ \____/\ \ ,__//\____\ \____\\ \_\
# \/____/\/___/  \/___/  \ \ \/ \/____/\/____/ \/_/
#                         \ \_\
#                          \/_/
#EOF
      end
    end

    def shutdown
      say "Shutting down..."
      Scheduler.instance.shutdown
      @web_server.stop
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
