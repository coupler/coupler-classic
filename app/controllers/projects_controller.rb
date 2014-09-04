module Coupler
  class ProjectsController
    include Coupler::Controller

    action 'New' do
      expose :project

      def call(params)
        @project = Project.new
      end
    end

    action 'Create' do
      include Lotus::Action::Session

      params do
        param :name, type: String, format: /.+/
        param :description
      end

      def call(params)
        valid = params.valid?

        project = Project.new({
          name: params[:name],
          description: params[:description]
        })
        if valid
          ProjectRepository.create(project)
          session[:project_newly_created] = project.id
          redirect_to '/projects/' + project.id.to_s
        end
      end
    end

    action 'Show' do
      include Lotus::Action::Session

      expose :project
      expose :newly_created

      def call(params)
        @project = ProjectRepository.find(params[:id])
        if session[:project_newly_created].to_s == params[:id].to_s
          @newly_created = true
          session[:project_newly_created] = nil
        end
      end
    end
  end
end
