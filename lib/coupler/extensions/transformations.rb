module Coupler
  module Extensions
    module Transformations
      def self.registered(app)
        app.get "/projects/:project_id/resources/:resource_id/transformations" do
          @project = Models::Project[:id => params[:project_id]]
          raise ProjectNotFound   unless @project
          @resource = @project.resources_dataset[:id => params[:resource_id]]
          raise ResourceNotFound  unless @resource
          @transformations = @resource.transformations
          erb('transformations/index'.to_sym)
        end

        app.get "/projects/:project_id/resources/:resource_id/transformations/new" do
          @project = Models::Project[:id => params[:project_id]]
          raise ProjectNotFound   unless @project
          @resource = @project.resources_dataset[:id => params[:resource_id]]
          raise ResourceNotFound  unless @resource
          @fields = @resource.selected_fields_dataset.order(:id).all
          @transformers = Models::Transformer.all
          @transformation = Models::Transformation.new(:transformer_attributes => {})
          erb 'transformations/new'.to_sym
        end

        app.post "/projects/:project_id/resources/:resource_id/transformations" do
          @project = Models::Project[:id => params[:project_id]]
          raise ProjectNotFound   unless @project
          @resource = @project.resources_dataset[:id => params[:resource_id]]
          raise ResourceNotFound  unless @resource
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
          raise ProjectNotFound   unless @project
          @resource = @project.resources_dataset[:id => params[:resource_id]]
          raise ResourceNotFound  unless @resource
          @transformation = @resource.transformations_dataset[:id => params[:id]]
          raise TransformationNotFound  unless @transformation
          @transformation.destroy
          redirect "/projects/#{@project.id}/resources/#{@resource.id}"
        end

        app.get "/projects/:project_id/resources/:resource_id/transformations/for/:field_name" do
          @project = Models::Project[:id => params[:project_id]]
          raise ProjectNotFound   unless @project
          @resource = @project.resources_dataset[:id => params[:resource_id]]
          raise ResourceNotFound  unless @resource
          @field = @resource.fields_dataset[:name => params[:field_name]]
          if @field
            @transformations = @field.transformations
            erb('transformations/for'.to_sym, :layout => false)
          else
            ''
          end
        end

        app.post "/projects/:project_id/resources/:resource_id/transformations/preview" do
          @project = Models::Project[:id => params[:project_id]]
          raise ProjectNotFound   unless @project
          @resource = @project.resources_dataset[:id => params[:resource_id]]
          raise ResourceNotFound  unless @resource

          @transformation = Models::Transformation.new(params[:transformation])
          @preview = @resource.preview_transformation(@transformation)
          erb(:"transformations/preview", :layout => false)
        end
      end
    end
  end
end
