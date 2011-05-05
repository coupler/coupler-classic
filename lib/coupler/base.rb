module Coupler
  class Base < Sinatra::Base

    inst_dir = File.expand_path(File.join(File.dirname(__FILE__), "..", ".."))
    set :environment, ENV['COUPLER_ENV'] || :production
    set :root, File.join(inst_dir, "webroot")
    set :static, true
    set :erb, :trim => '-'
    set :raise_errors, Proc.new { test? }
    set :show_exceptions, false
    set :dump_errors, true
    set :logging, Proc.new { !test? }
    set :methodoverride, true
    set :host, '127.0.0.1'
    set :db_path, lambda { |dbname| File.join(data_path, 'db', environment.to_s, dbname) }
    set :connection_string, lambda { |dbname| "jdbc:h2:#{db_path(dbname)};IGNORECASE=TRUE" }
    set :upload_path, lambda { File.join(data_path, 'uploads', environment.to_s) }
    set :log_path, lambda { File.join(data_path, 'log') }
    enable :sessions

    data_path = inst_dir
    if ENV['APPDATA']
      # Windows
      data_path = File.join(ENV['APPDATA'], "coupler")
    elsif !File.writable?(data_path)
      if ENV['HOME']
        dir = File.join(ENV['HOME'], ".coupler")
      else
        raise "don't know where to put data!"
      end
    end
    Dir.mkdir(data_path)  if !File.exist?(data_path)
    set :data_path, data_path

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
