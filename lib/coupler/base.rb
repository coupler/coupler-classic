module Coupler
  class Base < Sinatra::Base
    set :raise_errors, Proc.new { test? }
    set :show_exceptions, Proc.new { development? }
    set :dump_errors, true
    set :logging, Proc.new { !test? }
    enable :sessions

    use Rack::Flash
    register Extensions::Projects
    register Extensions::Resources

    get "/" do
      erb :index
    end
  end
end
