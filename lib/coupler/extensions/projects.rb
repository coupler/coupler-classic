module Coupler
  module Extensions
    module Projects
      def self.registered(app)
        app.get "/projects" do
          @projects = Models::Project.order(:id)
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

        app.get "/projects/:id" do
          @project = Models::Project[:id => params[:id]]
          raise ProjectNotFound   unless @project
          @resources = @project.resources
          @scenarios = @project.scenarios
          erb 'projects/show'.to_sym
        end

        app.get "/projects/:id/edit" do
          @project = Models::Project[:id => params[:id]]
          raise ProjectNotFound   unless @project
          erb 'projects/form'.to_sym
        end

        app.put "/projects/:id" do
          @project = Models::Project[:id => params[:id]]
          raise ProjectNotFound   unless @project
          @project.set(params[:project])
          if @project.valid?
            @project.save
            redirect '/projects'
          else
            erb 'projects/form'.to_sym
          end
        end

        app.delete "/projects/:id" do
          @project = Models::Project[:id => params[:id]]
          raise ProjectNotFound   unless @project
          @project.delete_versions_on_destroy = true  if params[:nuke] == "true"
          @project.destroy
          redirect '/projects'
        end
      end
    end
  end
end
