module Coupler
  class ProjectController
    include Coupler::Controller

    action 'New' do
      expose :project

      def call(params)
        @project = Project.new
      end
    end
  end
end
