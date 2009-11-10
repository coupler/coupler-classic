module Coupler
  class Base < Sinatra::Base
    set :root, COUPLER_ROOT
    set :static, true
    #set :port, 37222
    set :raise_errors, Proc.new { test? }
    set :show_exceptions, Proc.new { development? }
    set :dump_errors, true
    set :logging, Proc.new { !test? }
    enable :sessions

    use Rack::Flash
    register Extensions::Projects
    register Extensions::Resources
    register Extensions::Transformations
    helpers Coupler::Helpers

    get "/" do
      erb :index
    end

    get "/test" do
      erb :lorem_ipsum
    end
  end
end
