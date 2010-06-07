module Coupler
  module Extensions
    module Transformations
      def self.registered(app)
        app.get "/projects/:project_id/resources/:resource_id/transformations/new" do
          @project = Models::Project[:id => params[:project_id]]
          @resource = @project.resources_dataset[:id => params[:resource_id]]
          @fields = @resource.fields_dataset.filter(:is_selected => 1)
          @transformers = Models::Transformer.all
          @transformation = Models::Transformation.new
          erb 'transformations/new'.to_sym
        end

        app.post "/projects/:project_id/resources/:resource_id/transformations" do
          @project = Models::Project[:id => params[:project_id]]
          @resource = @project.resources_dataset[:id => params[:resource_id]]
          @fields = @resource.fields_dataset.filter(:is_selected => 1)
          @transformation = Models::Transformation.new(params[:transformation])
          @transformation.resource = @resource

          if @transformation.save
            flash[:notice] = "Transformation was successfully created."
            redirect "/projects/#{@project.id}/resources/#{@resource.id}"
          else
            @transformers = Models::Transformer.all
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

        app.get "/projects/:project_id/resources/:resource_id/transformations/for/:field_name" do
          @project = Models::Project[:id => params[:project_id]]
          @resource = @project.resources_dataset[:id => params[:resource_id]]
          @field = @resource.fields_dataset[:name => params[:field_name]]
          @transformations = @field.transformations
          erb('transformations/for'.to_sym, :layout => false)
        end

        app.get "/projects/:project_id/resources/:resource_id/transformations" do
          @project = Models::Project[:id => params[:project_id]]
          @resource = @project.resources_dataset[:id => params[:resource_id]]
          @transformations = @resource.transformations
          erb('transformations/index'.to_sym)
        end
      end
    end
  end
end
