module Coupler
  module Extensions
    module Scenarios
      def self.registered(app)
        app.get '/projects/:project_id/scenarios/new' do
          @project = Models::Project[:id => params[:project_id]]
          @scenario = Models::Scenario.new
          erb 'scenarios/new'.to_sym
        end

        app.post "/projects/:project_id/scenarios" do
          @project = Models::Project[:id => params[:project_id]]
          @scenario = Models::Scenario.new(params[:scenario])
          @scenario.project = @project

          if @scenario.save
            resources = @project.resources_dataset.filter(:id => params[:resource_ids])
            resources.each { |resource| @scenario.add_resource(resource) }

            flash[:newly_created] = true
            redirect "/projects/#{@project.id}/scenarios/#{@scenario.id}"
          else
            erb 'scenarios/new'.to_sym
          end
        end

        app.get '/projects/:project_id/scenarios/:id' do
          @project = Models::Project[:id => params[:project_id]]
          @scenario = @project.scenarios_dataset[:id => params[:id]]
          @resources = @scenario.resources
          @matchers = @scenario.matchers
          erb 'scenarios/show'.to_sym
        end

        app.get "/projects/:project_id/scenarios/:id/run" do
          @project = Models::Project[:id => params[:project_id]]
          @scenario = @project.scenarios_dataset[:id => params[:id]]
          Scheduler.instance.schedule_run_scenario_job(@scenario)
          erb 'scenarios/run'.to_sym
        end

        app.get "/projects/:project_id/scenarios/:id/progress" do
          scenario = Models::Scenario[:id => params[:id], :project_id => params[:project_id]]
          (scenario[:completed] * 100 / scenario[:total]).to_s
        end
      end
    end
  end
end
