module Coupler
  module Extensions
    module Transformers
      def self.registered(app)
        app.get "/transformers" do
          @transformers = Models::Transformer.all
          erb :'transformers/index'
        end

        app.post "/transformers/preview" do
          @transformer = Models::Transformer.new(params[:transformer])
          erb(:'transformers/preview', :layout => false)
        end

        app.get "/transformers/new" do
          @transformer = Models::Transformer.new
          erb :'transformers/new'
        end

        app.get '/transformers/:id' do
          @transformer = Models::Transformer[:id => params[:id]]
          erb :'transformers/show'
        end

        app.get "/transformers/:id/edit" do
          @transformer = Models::Transformer[:id => params[:id]]
          erb :'transformers/edit'
        end

        app.post "/transformers" do
          @transformer = Models::Transformer.new(params[:transformer])
          if @transformer.save
            redirect "/transformers"
          else
            erb :'transformers/new'
          end
        end

        app.put '/transformers/:id' do
          @transformer = Models::Transformer[:id => params[:id]]
          @transformer.set(params[:transformer])
          if @transformer.valid?
            @transformer.save
            redirect '/transformers'
          else
            erb :'transformers/edit'
          end
        end

        app.delete '/transformers/:id' do
          @transformer = Models::Transformer[:id => params[:id]]
          @transformer.destroy
          redirect '/transformers'
        end
      end
    end
  end
end
