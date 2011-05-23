module Coupler
  module Extensions
    module Imports
      def self.registered(app)
        app.post "/projects/:project_id/imports/upload" do
          @import = Models::Import.new(:data => params[:data], :project => @project)
          erb :'imports/new'
        end

        app.post "/projects/:project_id/imports" do
          @import = Models::Import.new(params[:import].merge(:project_id => @project.id))
          if @import.save
            Scheduler.instance.schedule_import_job(@import)
            redirect("/projects/#{@project.id}")
          else
            erb(:'imports/new')
          end
        end

        app.get "/projects/:project_id/imports/:id/edit" do
          @import = Models::Import[:id => params[:id], :project_id => @project.id]
          raise ImportNotFound    unless @import
          erb(:'imports/edit')
        end

        app.put "/projects/:project_id/imports/:id" do
          @import = Models::Import[:id => params[:id], :project_id => @project.id]
          raise ImportNotFound    unless @import
          @import.repair_duplicate_keys!(params[:delete])
          @resource = Models::Resource.create(:import => @import)
          redirect("/projects/#{@project.id}/resources/#{@resource.id}")
        end
      end
    end
  end
end
