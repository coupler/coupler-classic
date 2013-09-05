module Coupler
  class Application < Sinatra::Base
    set :root, Root.to_s
    enable :reload_templates if development?

    get "/" do
      erb :index
    end
  end
end
