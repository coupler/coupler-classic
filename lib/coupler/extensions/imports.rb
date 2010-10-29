module Coupler
  module Extensions
    module Imports
      def self.registered(app)
        app.post "/projects/:project_id/imports" do
          @import = Models::Import.new(params[:import].merge(:project => @project))
          if @import.valid?
            @import.save
            redirect "/projects/#{@project.id}/imports/#{@import.id}/edit"
          else
            # FIXME ;)
          end
        end

        app.get "/projects/:project_id/imports/:id/edit" do
          @import = Models::Import[:id => params[:id], :project_id => @project.id]
          raise ImportNotFound    unless @import
          @resource = Models::Resource.new
          erb :'imports/edit'
        end

        app.put "/projects/:project_id/imports/:id" do
          @import = Models::Import[:id => params[:id], :project_id => @project.id]
          raise ImportNotFound    unless @import
          @import.set(params[:import])
          @import.save

          @resource = Models::Resource.new(:import => @import)
          if @resource.valid?
            @resource.save
            redirect "/projects/#{@project.id}/resources/#{@resource.id}"
          else
            erb :'imports/edit'
          end
        end
      end
    end
  end
end
