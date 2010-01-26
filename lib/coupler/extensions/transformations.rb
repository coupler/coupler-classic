module Coupler
  module Extensions
    module Transformations
      def self.registered(app)
        app.get "/projects/:project_id/resources/:resource_id/transformations/new" do
          @project = Models::Project[:id => params[:project_id]]
          @resource = @project.resources_dataset[:id => params[:resource_id]]
          @transformation = Models::Transformation.new
          erb 'transformations/new'.to_sym
        end

        app.post "/projects/:project_id/resources/:resource_id/transformations" do
          @project = Models::Project[:id => params[:project_id]]
          @resource = @project.resources_dataset[:id => params[:resource_id]]
          @transformation = Models::Transformation.new(params[:transformation])
          @transformation.resource = @resource

          if @transformation.save
            redirect "/projects/#{@project.id}/resources/#{@resource.id}"
          else
            erb 'transformations/new'.to_sym
          end
        end

        app.delete "/projects/:project_id/resources/:resource_id/transformations/:id" do
          @project = Models::Project[:id => params[:project_id]]
          @resource = @project.resources_dataset[:id => params[:resource_id]]
          @transformation = @resource.transformations_dataset[:id => params[:id]]
          @transformation.destroy
          redirect "/projects/#{@project.id}/resources/#{@resource.id}"
        end
      end
    end
  end
end
