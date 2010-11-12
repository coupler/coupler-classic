module Coupler
  module Extensions
    module Projects
      def self.registered(app)
        app.before do
          md = request.path_info.match(%r{/projects/(\d+)/?})
          if md
            # NOTE: Using regex matching here sucks, but apparently Sinatra
            #       calls before filters before params are parsed.
            @project = Models::Project[:id => md[1]]
            raise ProjectNotFound   unless @project
            @project.touch!
          end
        end

        app.get "/projects" do
          @projects = Models::Project.order(:id)
          @resource_counts = Models::Resource.count_by_project
          @scenario_counts = Models::Scenario.count_by_project
          erb 'projects/index'.to_sym
        end

        app.get "/projects/new" do
          @project = Models::Project.new
          erb 'projects/form'.to_sym
        end

        app.post "/projects" do
          @project = Models::Project.create(params['project'])
          flash[:newly_created] = true
          redirect "/projects/#{@project.id}"
        end

        app.get "/projects/:project_id" do
          @resources = @project.resources
          @scenarios = @project.scenarios
          erb 'projects/show'.to_sym
        end

        app.get "/projects/:project_id/edit" do
          erb 'projects/form'.to_sym
        end

        app.put "/projects/:project_id" do
          @project.set(params[:project])
          if @project.valid?
            @project.save
            redirect '/projects'
          else
            erb 'projects/form'.to_sym
          end
        end

        app.delete "/projects/:project_id" do
          @project.delete_versions_on_destroy = true  if params[:nuke] == "true"
          @project.destroy
          redirect '/projects'
        end
      end
    end
  end
end
