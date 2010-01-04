module Coupler
  module Extensions
    module Scenarios
      def self.registered(app)
        app.get '/projects/:slug/scenarios/:id' do
          @project = Models::Project[:slug => params[:slug]]
          @scenario = @project.scenarios_dataset[:id => params[:id]]
          erb 'scenarios/show'.to_sym
        end
      end
    end
  end
end
