module Coupler::Extensions::Projects
  def self.registered(app)
    app.get "/projects" do
      @projects = Coupler::Project.order(:id)
      erb 'projects/index'.to_sym
    end

    app.get "/projects/new" do
      erb 'projects/new'.to_sym
    end

    app.post "/projects" do
      project = Coupler::Project.create(params['project'])
      flash[:newly_created] = true
      redirect "/projects/#{project.id}"
    end

    app.get "/projects/:project_id" do
      @project = Coupler::Project[:id => params[:project_id]]
      erb 'projects/show'.to_sym
    end
  end
end
