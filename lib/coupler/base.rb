module Coupler
  class Base < Sinatra::Base
    register Extensions::Databases
    register Extensions::Resources

    get "/" do
      erb :index
    end
  end
end
