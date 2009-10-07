module Coupler
  class Base < Sinatra::Base
    enable :sessions
    use Rack::CommonLogger
    #use Rack::ShowExceptions
    use Rack::Flash
    register Extensions::Projects
    register Extensions::Resources

    get "/" do
      erb :index
    end
  end
end
