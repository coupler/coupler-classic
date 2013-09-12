module Coupler
  class Application < Sinatra::Base
    set :root, Root.to_s
    enable :reload_templates if development?

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

    after do
      session['flash'] = session['new_flash']
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
      attribs['data'] = upload[:tempfile].read
      attribs['filename'] = upload[:filename]

      file = File.new
      file.set_only(attribs, :data, :filename, :col_sep, :row_sep, :quote_char)
      if file.valid?
        file.save
      else
        flash('notice', 'File upload was invalid.')
        flash('notice_class', 'error')
      end
      redirect '/files'
    end

    post "/files/:id" do
      file = File[:id => params['id']]
      file.set_only(params['file'], :col_sep, :row_sep, :quote_char)
      file.save if file.valid?
      redirect '/files'
    end
  end
end
