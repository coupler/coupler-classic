module Coupler
  module Extensions
    module Resources
      def self.registered(app)
        app.get "/projects/:project_id/resources" do
          @resources = @project.resources
          erb 'resources/index'.to_sym
        end

        app.get "/projects/:project_id/resources/new" do
          @connections = Models::Connection.all
          @resource = Models::Resource.new
          if @connections.empty?
            @resource.connection_attributes = {}
          end
          erb 'resources/new'.to_sym
        end

        app.post "/projects/:project_id/resources" do
          @resource = Models::Resource.new(params[:resource])
          @resource.project = @project

          if @resource.save
            flash[:notice] = "Resource was created successfully!  Now you can choose which fields you wish to select."
            redirect "/projects/#{@project.id}/resources/#{@resource.id}/edit"
          else
            @connections = Models::Connection.all
            erb 'resources/new'.to_sym
          end
        end

        app.get "/projects/:project_id/resources/:id" do
          @resource = @project.resources_dataset[:id => params[:id]]
          raise ResourceNotFound  unless @resource
          @fields = @resource.fields_dataset.filter(:is_selected => 1).all
          @transformers = Models::Transformer.all
          @transformations = @resource.transformations_dataset.order(:position)
          @scenarios = @resource.scenarios
          @job = @resource.jobs_dataset[:status => %w{running scheduled}]
          erb 'resources/show'.to_sym
        end

        app.get "/projects/:project_id/resources/:id/transform" do
          @resource = @project.resources_dataset[:id => params[:id]]
          raise ResourceNotFound  unless @resource
          Scheduler.instance.schedule_transform_job(@resource)
          redirect "/projects/#{@project.id}/resources/#{@resource.id}"
        end

        app.get "/projects/:project_id/resources/:id/edit" do
          @resource = @project.resources_dataset[:id => params[:id]]
          raise ResourceNotFound  unless @resource
          @fields = @resource.fields
          @selection_count = @resource.fields_dataset.filter(:is_selected => true).count
          erb 'resources/edit'.to_sym
        end

        app.put "/projects/:project_id/resources/:id" do
          @resource = @project.resources_dataset[:id => params[:id]]
          raise ResourceNotFound  unless @resource

          @resource.set(params[:resource])  if params[:resource]
          if @resource.valid?
            # FIXME
            #flash[:notice] = "Resource successfully created!  Next, if you want to change this resource's fields, you'll need to add transformations."

            @resource.save
            redirect "/projects/#{@project.id}/resources/#{@resource.id}"
          else
            @fields = @resource.fields
            @selection_count = @resource.fields_dataset.filter(:is_selected => true).count
            erb 'resources/edit'.to_sym
          end
        end

        app.get "/projects/:project_id/resources/:id/record/:record_id" do
          @resource = @project.resources_dataset[:id => params[:id]]
          raise ResourceNotFound  unless @resource

          @record = nil
          @resource.final_dataset do |ds|
            @record = ds.filter(@resource.primary_key_sym => params[:record_id]).first
          end
          @record.to_json
        end
      end
    end
  end
end
