module Coupler
  class DatasetsController
    include Coupler::Controller

    action 'New' do
      expose :project

      def call(params)
        @project = ProjectRepository.find(params[:project_id])
      end
    end
  end
end
