module Coupler
  module Extensions
    module Results
      module Helpers
        def resource_optgroup_tag(resource_id)
          if resource_id.is_a?(String)
            id, which = resource_id.split(/_/).collect(&:to_i)
            %{<optgroup class="resource-#{id}" label="#{@resources[id].name} [#{which+1}]">}
          else
            %{<optgroup class="resource-#{resource_id}" label="#{@resources[resource_id].name}">}
          end
        end
      end

      def self.registered(app)
        app.helpers Helpers

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

          @scenario.local_database do |scenario_db|
            groups_ds = scenario_db[@result.groups_table_name]
            @group = groups_ds.filter(:id => params[:group_id]).first
          end
          erb(:"results/details", :layout => false)
        end

        app.post '/projects/:project_id/scenarios/:scenario_id/results/:id/details/:group_id/record' do
          @scenario = @project.scenarios_dataset[:id => params[:scenario_id]]
          raise ScenarioNotFound  unless @scenario
          @result = @scenario.results_dataset[:id => params[:id]]

          record_id = nil
          @result.groups_records_dataset do |ds|
            record_id = ds.filter(:group_id => params[:group_id], :which => params[:which]).
              limit(1, params[:index].to_i).first[:record_id]
          end
          resource =
            case params[:which]
            when nil, '', '0' then @scenario.resource_1
            when '1' then @scenario.resource_2
            end
          resource.final_dataset do |ds|
            @columns = ds.columns
            @record = ds.select(*@columns).filter(resource.primary_key_sym => record_id).first
          end
          erb(:"results/record", :layout => false)
        end

=begin
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
=end
      end
    end
  end
end
