module Coupler
  class Base < Sinatra::Base

    set :environment, ENV['COUPLER_ENV'] || :production
    set :root, File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "webroot"))
    set :static, true
    set :erb, :trim => '-'
    set :raise_errors, Proc.new { test? }
    set :show_exceptions, false
    set :dump_errors, true
    set :logging, Proc.new { !test? }
    set :methodoverride, true
    set :host, '127.0.0.1'
    enable :sessions

    use Rack::Flash
    register Extensions::Connections
    register Extensions::Projects
    register Extensions::Resources
    register Extensions::Transformations
    register Extensions::Scenarios
    register Extensions::Matchers
    register Extensions::Results
    register Extensions::Jobs
    register Extensions::Transformers
    register Extensions::Imports
    register Extensions::Exceptions

    # Monkey patch :/
    def self.run!(options={})
      set options
      handler      = detect_rack_handler
      handler_name = handler.name.gsub(/.*::/, '')
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
      puts "== Sinatra/#{Sinatra::VERSION} has taken the stage " +
        "on #{port} for #{environment} with backup from #{handler_name}" unless handler_name =~/cgi/i
      handler.run self, :Host => bind, :Port => port do |server|
        trap(:INT) do
          ## Use thins' hard #stop! if available, otherwise just #stop
          server.respond_to?(:stop!) ? server.stop! : server.stop
          puts "\n== Sinatra has ended his set (crowd applauds)" unless handler_name =~/cgi/i
          yield server if block_given?
        end
        set :running, true
      end
    rescue Errno::EADDRINUSE => e
      puts "== Someone is already performing on port #{port}!"
    end

    helpers do
      include Coupler::Helpers
      include Rack::Utils
      alias_method :h, :escape_html
    end

    #before do
    #end

    get "/" do
      if Models::Project.count > 0
        redirect "/projects"
      else
        session[:first_use] = true
        erb :index
      end
    end
  end
end
