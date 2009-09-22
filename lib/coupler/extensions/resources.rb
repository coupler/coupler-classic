module Coupler::Extensions::Resources
  def self.registered(app)
    app.get "/resources" do
      @resources = Coupler::Resource.order(:id)
      erb 'resources/index'.to_sym
    end

    app.get "/resources/new" do
      @databases = Coupler::Database.order(:id)
      erb 'resources/new'.to_sym
    end

    app.post "/resources" do
      Coupler::Resource.create(params['resource'])
      redirect "/resources"
    end
  end
end
