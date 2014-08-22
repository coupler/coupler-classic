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
          redirect_to '/projects/' + project.id.to_s
        end
      end
    end
  end
end
