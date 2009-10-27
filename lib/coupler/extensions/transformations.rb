module Coupler
  module Extensions
    module Transformations
      def self.registered(app)
        app.get "/projects/:slug/resources/:resource_id/transformations/new" do
          @project = Models::Project[:slug => params[:slug]]
          @resource = @project.resources_dataset[:id => params[:resource_id]]
          @transformation = Models::Transformation.new
          erb 'transformations/new'.to_sym
        end

        app.post "/projects/:slug/resources/:resource_id/transformations" do
          @project = Models::Project[:slug => params[:slug]]
          @resource = @project.resources_dataset[:id => params[:resource_id]]
          @transformation = Models::Transformation.new(params[:transformation])
          @transformation.resource = @resource

          if @transformation.save
            redirect "/projects/#{@project.slug}/resources/#{@resource.id}"
          else
            erb 'transformations/new'.to_sym
          end
        end
      end
    end
  end
end
