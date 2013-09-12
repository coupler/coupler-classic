module Coupler
  class Application < Sinatra::Base
    set :root, Root.to_s
    enable :reload_templates if development?

    get "/" do
      erb :index
    end

    get "/files" do
      @files = File.all
      erb :"files/index"
    end

    post "/files" do
      file = File.new({
        :data => params['file'][:tempfile].read,
        :filename => params['file'][:filename]
      })
      file.save if file.valid?
      redirect '/files'
    end
  end
end
