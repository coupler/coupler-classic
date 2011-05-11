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
    set(:data_path, lambda {
      # NOTE: Unfortunately, this code is in two places. Coupler can
      # be run with or without the launcher, and the launcher needs
      # to know about Coupler's data path before it runs Coupler.
      dir =
        if ENV['COUPLER_HOME']
          ENV['COUPLER_HOME']
        else
          case Config::CONFIG['host_os']
          when /mswin|windows/i
            # Windows
            File.join(ENV['APPDATA'], "coupler")
          else
            if ENV['HOME']
              File.join(ENV['HOME'], ".coupler")
            else
              raise "Can't figure out where Coupler lives! Try setting the COUPLER_HOME environment variable"
            end
          end
        end
      if !File.exist?(dir)
        begin
          Dir.mkdir(dir)
        rescue SystemCallError
          raise "Can't create Coupler directory (#{dir})! Is the parent directory accessible?"
        end
      end
      if !File.writable?(dir)
        raise "Coupler directory (#{dir}) is not writable!"
      end
      File.expand_path(dir)
    })
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
