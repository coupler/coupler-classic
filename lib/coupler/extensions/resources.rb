module Coupler::Extensions::Resources
  def self.registered(app)
    app.get "/projects/:slug/resources" do
      @project = Coupler::Project[:slug => params[:slug]]
      @resources = @project.resources
      erb 'resources/index'.to_sym
    end

    app.get "/projects/:slug/resources/new" do
      @project = Coupler::Project[:slug => params[:slug]]
      @resource = Coupler::Resource.new
      erb 'resources/new'.to_sym
    end

    app.post "/projects/:slug/resources" do
      @project = Coupler::Project[:slug => params[:slug]]

      @resource = Coupler::Resource.new(params[:resource])
      @resource.project = @project

      if @resource.save
        flash[:newly_created] = true
        redirect "/projects/#{@project.slug}/resources/#{@resource.id}"
      else
        erb 'resources/new'.to_sym
      end
    end

    app.get "/projects/:slug/resources/:id" do
      @project = Coupler::Project[:slug => params[:slug]]
      @resource = Coupler::Resource[:id => params[:id], :project_id => @project.id]
      erb 'resources/show'.to_sym
    end
  end
end
