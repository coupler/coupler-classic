module Coupler
  module Extensions
    module Scenarios
      def self.registered(app)
        app.get '/projects/:slug/scenarios/new' do
          @project = Models::Project[:slug => params[:slug]]
          @scenario = Models::Scenario.new
          erb 'scenarios/new'.to_sym
        end

        app.post "/projects/:slug/scenarios" do
          @project = Models::Project[:slug => params[:slug]]
          @scenario = Models::Scenario.new(params[:scenario])
          @scenario.project = @project

          if @scenario.save
            resources = @project.resources_dataset.filter(:id => params[:resource_ids])
            resources.each { |resource| @scenario.add_resource(resource) }

            flash[:newly_created] = true
            redirect "/projects/#{@project.slug}/scenarios/#{@scenario.id}"
          else
            erb 'scenarios/new'.to_sym
          end
        end

        app.get '/projects/:slug/scenarios/:id' do
          @project = Models::Project[:slug => params[:slug]]
          @scenario = @project.scenarios_dataset[:id => params[:id]]
          erb 'scenarios/show'.to_sym
        end
      end
    end
  end
end
