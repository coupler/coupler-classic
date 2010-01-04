module Coupler
  module Extensions
    module Projects
      def self.registered(app)
        app.get "/projects" do
          @projects = Models::Project.order(:id)
          erb 'projects/index'.to_sym
        end

        app.get "/projects/new" do
          erb 'projects/new'.to_sym
        end

        app.post "/projects" do
          project = Models::Project.create(params['project'])
          flash[:newly_created] = true
          redirect "/projects/#{project.slug}"
        end

        app.get "/projects/:slug" do
          @project = Models::Project[:slug => params[:slug]]
          @resources = @project.resources
          @scenarios = @project.scenarios
          erb 'projects/show'.to_sym
        end
      end
    end
  end
end
