module Coupler
  module Extensions
    module Connections
      def self.registered(app)
        app.get "/connections" do
          @connections = Models::Connection.all
          erb :'connections/index'
        end

        app.get "/connections/new" do
          @connection = Models::Connection.new
          erb :'connections/new'
        end

        app.post "/connections" do
          @connection = Models::Connection.new(params[:connection])

          if @connection.save
            if session[:return_to]
              flash[:notice] = "Connection was successfully created.  You can now create a resource for that connection."
              redirect session[:return_to]
              session[:return_to] = nil
            else
              flash[:notice] = "Connection was successfully created."
              redirect "/connections"
            end
          else
            erb 'connections/new'.to_sym
          end
        end
      end
    end
  end
end
