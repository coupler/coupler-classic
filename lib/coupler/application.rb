module Coupler
  class Application < Sinatra::Base
    set :root, Root.to_s
    enable :reload_templates if development?
    enable :sessions

    helpers do
      def flash(*args)
        if args.empty?
          raise ArgumentError, "wrong number of arguments (0 for 1..2)"
        end

        if args.length == 1
          session.has_key?('flash') ? session['flash'][args[0]] : nil
        else
          session['new_flash'] ||= {}
          session['new_flash'][args[0]] = args[1]
        end
      end
    end
    helpers HtmlHelpers

    after do
      session['flash'] = session.delete('new_flash')
    end

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
      if upload
        attribs['data'] = upload[:tempfile].read
        attribs['filename'] = upload[:filename]
      end

      file = File.new
      file.set_only(attribs, :data, :filename, :format)
      if file.valid?
        file.save
      else
        flash('notice', 'File upload was invalid.')
        flash('notice_class', 'error')
      end
      redirect '/files'
    end

    get "/files/:id/clean" do
      @file = File[:id => params['id']]
      erb :"files/clean"
    end

    post "/files/:id" do
      file = File[:id => params['id']]
      file.set_only(params['file'], :col_sep, :row_sep, :quote_char)
      file.save if file.valid?
      redirect '/files'
    end

    get "/files/:id/table" do
      @file = File[:id => params['id']]

      if params['col_sep']
        @file.col_sep = params['col_sep']
      end

      if params['row_sep']
        @file.row_sep = params['row_sep']
      end

      if params['quote_char']
        @file.quote_char = params['quote_char']
      end

      erb :"files/table", :layout => false
    end
  end
end
