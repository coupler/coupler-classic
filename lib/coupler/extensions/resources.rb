module Coupler
  module Extensions
    module Resources
      def self.registered(app)
        app.get "/projects/:project_id/resources/new" do
          @project = Models::Project[:id => params[:project_id]]
          @resource = Models::Resource.new
          erb 'resources/new'.to_sym
        end

        app.post "/projects/:project_id/resources" do
          @project = Models::Project[:id => params[:project_id]]

          @resource = Models::Resource.new(params[:resource])
          @resource.project = @project

          if @resource.save
            flash[:newly_created] = true
            redirect "/projects/#{@project.id}/resources/#{@resource.id}"
          else
            erb 'resources/new'.to_sym
          end
        end

        app.get "/projects/:project_id/resources/:id" do
          @project = Models::Project[:id => params[:project_id]]
          @resource = @project.resources_dataset[:id => params[:id]]
          @transformers = Models::Transformer.all
          @transformations = @resource.transformations_per_field
          @t12n_count = @resource.transformations_dataset.count
          @scenarios = @resource.scenarios
          @running_jobs = @resource.running_jobs
          @scheduled_jobs = @resource.scheduled_jobs
          erb 'resources/show'.to_sym
        end

        app.get "/projects/:project_id/resources/:id/transform" do
          @project = Models::Project[:id => params[:project_id]]
          @resource = @project.resources_dataset[:id => params[:id]]
          Scheduler.instance.schedule_transform_job(@resource)
          redirect "/projects/#{@project.id}/resources/#{@resource.id}"
        end

        #app.get "/projects/:project_id/resources/:id/progress" do
          #resource = Models::Resource[:project_id => params[:project_id], :id => params[:id]]
          #(resource[:completed] * 100 / resource[:total]).to_s
        #end
      end
    end
  end
end
