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
      attribs = params['file']
      upload = attribs.delete('upload')
      attribs['data'] = upload[:tempfile].read
      attribs['filename'] = upload[:filename]

      file = File.new
      file.set_only(attribs, :data, :filename, :col_sep, :row_sep, :quote_char)
      file.save if file.valid?
      redirect '/files'
    end
  end
end
