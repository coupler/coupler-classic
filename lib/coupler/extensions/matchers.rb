module Coupler
  module Extensions
    module Matchers
      def self.registered(app)
        app.get "/projects/:project_id/scenarios/:scenario_id/matchers/new" do
          @project = Models::Project[:id => params[:project_id]]
          @scenario = @project.scenarios_dataset[:id => params[:scenario_id]]
          @matcher = Models::Matcher.new
          erb 'matchers/form'.to_sym
        end

        app.get "/projects/:project_id/scenarios/:scenario_id/matchers/:id/edit" do
          @project = Models::Project[:id => params[:project_id]]
          @scenario = @project.scenarios_dataset[:id => params[:scenario_id]]
          @matcher = @scenario.matchers_dataset[:id => params[:id]]
          erb 'matchers/form'.to_sym
        end

        app.post "/projects/:project_id/scenarios/:scenario_id/matchers" do
          @project = Models::Project[:id => params[:project_id]]
          @scenario = @project.scenarios_dataset[:id => params[:scenario_id]]
          @matcher = Models::Matcher.new(params[:matcher])
          @matcher.scenario = @scenario

          if @matcher.save
            flash[:notice] = "Matcher was successfully created."
            redirect "/projects/#{@project.id}/scenarios/#{@scenario.id}"
          else
            erb 'matchers/form'.to_sym
          end
        end

        app.put "/projects/:project_id/scenarios/:scenario_id/matchers/:id" do
          @project = Models::Project[:id => params[:project_id]]
          @scenario = @project.scenarios_dataset[:id => params[:scenario_id]]
          @matcher = @scenario.matchers_dataset[:id => params[:id]]
          @matcher.set(params[:matcher])

          if @matcher.valid?
            @matcher.save
            redirect "/projects/#{@project.id}/scenarios/#{@scenario.id}"
          else
            erb 'matchers/form'.to_sym
          end
        end

        app.delete "/projects/:project_id/scenarios/:scenario_id/matchers/:id" do
          @project = Models::Project[:id => params[:project_id]]
          @scenario = @project.scenarios_dataset[:id => params[:scenario_id]]
          @matcher = @scenario.matchers_dataset[:id => params[:id]]
          @matcher.destroy
          redirect "/projects/#{@project.id}/scenarios/#{@scenario.id}"
        end
      end
    end
  end
end
