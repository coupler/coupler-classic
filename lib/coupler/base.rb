module Coupler
  class Base < Sinatra::Base
    def self.run!(*args)
      scheduler = Scheduler.instance
      scheduler.start
      at_exit { scheduler.shutdown }
      super
    end

    set :root, File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "webroot"))
    set :static, true
    #set :port, 37222
    set :raise_errors, Proc.new { test? }
    set :show_exceptions, Proc.new { development? }
    set :dump_errors, true
    set :logging, Proc.new { !test? }
    set :methodoverride, true
    enable :sessions

    use Rack::Flash
    register Extensions::Projects
    register Extensions::Resources
    register Extensions::Transformations
    register Extensions::Scenarios
    register Extensions::Matchers
    register Extensions::Results
    register Extensions::Jobs
    register Extensions::Transformers
    helpers do
      include Coupler::Helpers
      include Rack::Utils
      alias_method :h, :escape_html
    end

    get "/" do
      if Models::Project.count > 0
        redirect "/projects"
      else
        erb :index
      end
    end

    # Use the contents of the file at +path+ as the response body.
    # NOTE: this is a workaround for:
    #   http://jira.codehaus.org/browse/JRUBY-4594
    #def send_file(path, opts={})
      #data = open(path).read
      #last_modified File.stat(path).mtime

      #content_type media_type(opts[:type]) ||
        #media_type(File.extname(path)) ||
        #response['Content-Type'] ||
        #'application/octet-stream'

      #response['Content-Length'] ||= (opts[:length] || data.length).to_s

      #if opts[:disposition] == 'attachment' || opts[:filename]
        #attachment opts[:filename] || path
      #elsif opts[:disposition] == 'inline'
        #response['Content-Disposition'] = 'inline'
      #end

      #halt data
    #rescue Errno::ENOENT
      #not_found
    #end
  end
end
