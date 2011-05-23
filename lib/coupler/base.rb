module Coupler
  class Base < Sinatra::Base

    inst_dir = File.expand_path(File.join(File.dirname(__FILE__), "..", ".."))
    set :environment, Coupler.environment
    set :root, File.join(inst_dir, "webroot")
    set :static, true
    set :erb, :trim => '-'
    set :raise_errors, Proc.new { test? }
    set :show_exceptions, false
    set :dump_errors, true
    set :logging, Proc.new { !test? }
    set :methodoverride, true
    set :bind, '127.0.0.1'
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
    register Extensions::Notifications
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
