module Coupler
  module Extensions
    module Results
      def self.registered(app)
        app.get '/projects/:project_id/scenarios/:scenario_id/results' do
          @scenario = @project.scenarios_dataset[:id => params[:scenario_id]]
          raise ScenarioNotFound  unless @scenario
          @results = @scenario.results_dataset.order(:id.desc)
          erb 'results/index'.to_sym
        end

        app.get '/projects/:project_id/scenarios/:scenario_id/results/:id' do
          @scenario = @project.scenarios_dataset[:id => params[:scenario_id]]
          raise ScenarioNotFound  unless @scenario
          @result = @scenario.results_dataset[:id => params[:id]]

          html = nil
          @result.groups_dataset do |groups_dataset|
            html = erb(:"results/show", {}, {:groups_dataset => groups_dataset})
          end
          html
        end

        app.get '/projects/:project_id/scenarios/:scenario_id/results/:id/details/:group_id' do
          @scenario = @project.scenarios_dataset[:id => params[:scenario_id]]
          raise ScenarioNotFound  unless @scenario
          @result = @scenario.results_dataset[:id => params[:id]]

          html = nil
          @scenario.local_database do |scenario_db|
            groups_ds = scenario_db[@result.groups_table_name]
            groups_records_ds = scenario_db[@result.groups_records_table_name]

            @group = groups_ds.filter(:id => params[:group_id]).first
            @records_dataset = groups_records_ds.filter(:group_id => params[:group_id])
            html = erb(:"results/details", :layout => false)
          end
          html
        end

        app.get '/projects/:project_id/scenarios/:scenario_id/results/:id.csv' do
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
