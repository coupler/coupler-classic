module Coupler
  module Extensions
    module Results
      def self.registered(app)
        app.get '/projects/:project_id/scenarios/:scenario_id/results' do
          @project = Models::Project[:id => params[:project_id]]
          @scenario = @project.scenarios_dataset[:id => params[:scenario_id]]
          @results = @scenario.results
          erb 'results/index'.to_sym
        end

        app.get '/projects/:project_id/scenarios/:scenario_id/results/:id' do
          @project = Models::Project[:id => params[:project_id]]
          @scenario = @project.scenarios_dataset[:id => params[:scenario_id]]
          @result = @scenario.results_dataset[:id => params[:id]]

          filename = "#{@scenario.slug}-run-#{@result.created_at.strftime('%Y%m%d%H%M')}.csv"
          attachment(filename)
          @result.to_csv
        end
      end
    end
  end
end
