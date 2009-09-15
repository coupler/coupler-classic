module Coupler::Extensions::Resources
  def self.registered(app)
    #app.get "/databases" do
      #@databases = Coupler::Database.order(:id)
      #erb 'databases/index'.to_sym
    #end

    #app.get "/databases/new" do
      #erb 'databases/new'.to_sym
    #end

    #app.post "/databases" do
      #Coupler::Database.create(params['database'])
      #redirect "/databases"
    #end
  end
end
