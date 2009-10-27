module Coupler
  module Extensions
    module Resources
      def self.registered(app)
        app.get "/projects/:slug/resources" do
          @project = Models::Project[:slug => params[:slug]]
          @resources = @project.resources
          erb 'resources/index'.to_sym
        end

        app.get "/projects/:slug/resources/new" do
          @project = Models::Project[:slug => params[:slug]]
          @resource = Models::Resource.new
          erb 'resources/new'.to_sym
        end

        app.post "/projects/:slug/resources" do
          @project = Models::Project[:slug => params[:slug]]

          @resource = Models::Resource.new(params[:resource])
          @resource.project = @project

          if @resource.save
            flash[:newly_created] = true
            redirect "/projects/#{@project.slug}/resources/#{@resource.id}"
          else
            erb 'resources/new'.to_sym
          end
        end

        app.get "/projects/:slug/resources/:id" do
          @project = Models::Project[:slug => params[:slug]]
          @resource = @project.resources_dataset[:id => params[:id]]
          @transformations = @resource.transformations
          erb 'resources/show'.to_sym
        end
      end
    end
  end
end
