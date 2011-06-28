module Coupler
  module Extensions
    module Connections
      include Models

      def self.registered(app)
        app.get "/connections" do
          @connections = Connection.all
          erb :'connections/index'
        end

        app.get "/connections/new" do
          @connection = Connection.new
          erb :'connections/new'
        end

        app.get "/connections/:id" do
          @connection = Connection[:id => params[:id]]
          @resources = @connection.resources
          erb :'connections/show'
        end

        app.post "/connections" do
          @connection = Connection.new(params[:connection])

          if @connection.save
            flash[:notice] = "Connection was successfully created."
            redirect "/connections"
          else
            erb 'connections/new'.to_sym
          end
        end

        app.delete "/connections/:id" do
          @connection = Connection[params[:id]]
          if @connection.destroy
            flash[:notice] = "Connection was successfully deleted."
          else
            flash[:notice] = "Connection could not be deleted."
            flash[:notice_class] = "error"
          end
          redirect "/connections"
        end
      end
    end
  end
end
