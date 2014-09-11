module Coupler
  class DatasetsController
    include Coupler::Controller

    action 'New' do
      expose :project, :import

      def call(params)
        @project = ProjectRepository.find(params[:project_id])
        @import = Import.new
      end
    end
  end
end
