module Coupler
  class Base < Sinatra::Base
    register Extensions::Databases

    get "/" do
      erb :index
    end
  end
end
