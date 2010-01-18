module Coupler
  module Extensions
    module Matchers
      def self.registered(app)
        app.get "/projects/:slug/scenarios/:scenario_id/matchers/new" do
          @project = Models::Project[:slug => params[:slug]]
          @scenario = @project.scenarios_dataset[:id => params[:scenario_id]]
          @matcher = Models::Matcher.new
          erb 'matchers/new'.to_sym
        end

        app.post "/projects/:slug/scenarios/:scenario_id/matchers" do
          @project = Models::Project[:slug => params[:slug]]
          @scenario = @project.scenarios_dataset[:id => params[:scenario_id]]
          @matcher = Models::Matcher.new(params[:matcher])
          @matcher.scenario = @scenario

          if @matcher.save
            redirect "/projects/#{@project.slug}/scenarios/#{@scenario.id}"
          else
            erb 'matchers/new'.to_sym
          end
        end
      end
    end
  end
end
