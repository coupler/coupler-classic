module Coupler
  CONFIG_PATH = File.dirname(__FILE__) + "/../../config/"

  Config = Sequel.connect(
    Coupler::Server.instance.connection_string(
      COUPLER_ENV ? "coupler_#{COUPLER_ENV}" : "coupler",
      :create_database => true
    )
  )

  # FIXME: this should happen lazily!
  if Config.tables.empty?
    Config.create_table :projects do
      primary_key :id
      String :name
      String :description
      String :slug
    end

    Config.create_table :resources do
      primary_key :id
      String :name
      String :adapter
      String :host
      Integer :port
      String :username
      String :password
      String :database_name
      String :table_name
      Integer :project_id
    end

    Config.create_table :transformations do
      primary_key :id
      String :name
      String :field_name
      String :method_name
      Integer :resource_id
    end
  end
end
