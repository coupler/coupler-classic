module Coupler
  module Extensions
    module Imports
      def self.registered(app)
        app.post "/projects/:project_id/imports/upload" do
          uploader = DataUploader.new
          uploader.store!(params[:data])
          @import = Models::Import.new(:file_name => uploader.store_path, :project => @project)
          erb :'imports/new'
        end

        app.get "/projects/:project_id/imports/:id/edit" do
          @import = Models::Import[:id => params[:id], :project_id => @project.id]
          raise ImportNotFound    unless @import
          @resource = Models::Resource.new(:import => @import)
          erb :'imports/edit'
        end

        app.put "/projects/:project_id/imports/:id" do
          @import = Models::Import[:id => params[:id], :project_id => @project.id]
          raise ImportNotFound    unless @import
          @import.set(params[:import])
          @resource = Models::Resource.new(:import => @import)

          if !@import.save || !@resource.valid? || !@import.import!
            return erb(:'imports/edit')
          end

          @resource.save
          redirect "/projects/#{@project.id}/resources/#{@resource.id}"
        end
      end
    end
  end
end
