module Coupler
  module Extensions
    module Results
      def self.registered(app)
        app.get '/projects/:project_id/scenarios/:scenario_id/results' do
          @project = Models::Project[:id => params[:project_id]]
          raise ProjectNotFound   unless @project
          @scenario = @project.scenarios_dataset[:id => params[:scenario_id]]
          raise ScenarioNotFound  unless @scenario
          @results = @scenario.results
          erb 'results/index'.to_sym
        end

        app.get '/projects/:project_id/scenarios/:scenario_id/results/:id' do
          @project = Models::Project[:id => params[:project_id]]
          raise ProjectNotFound   unless @project
          @scenario = @project.scenarios_dataset[:id => params[:scenario_id]]
          raise ScenarioNotFound  unless @scenario
          @result = @scenario.results_dataset[:id => params[:id]]
          raise ResultNotFound    unless @result
          @snapshot = @result.snapshot

          filename = "#{@scenario.slug}-run-#{@result.created_at.strftime('%Y%m%d-%H%M')}.txt"
          content_type('text/plain')
          attachment(filename)
          erb :'results/show', :layout => false
        end
      end
    end
  end
end
