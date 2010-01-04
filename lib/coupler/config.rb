module Coupler
  CONFIG_PATH = File.dirname(__FILE__) + "/../../config/"

  class Config < Delegator
    include Singleton

    def initialize
      database_name = COUPLER_ENV ? "coupler_#{COUPLER_ENV}" : "coupler"
      connection_string = Coupler::Server.instance.connection_string(database_name, :create_database => true)
      @database = Sequel.connect(connection_string, :loggers => [Coupler.logger])
      super(@database)

      if @database.tables.empty?
        create_schema
      end
    end

    def __getobj__
      @database
    end

    def create_schema
      if COUPLER_ENV == "test"
        # FIXME: this isn't really the best solution
        Sequel::MySQL.default_engine = "InnoDB"
      end

      @database.create_table :projects do
        primary_key :id
        String :name
        String :slug
        String :description
        Time :created_at
        Time :updated_at
      end

      @database.create_table :resources do
        primary_key :id
        String :name
        String :slug
        String :adapter
        String :host
        Integer :port
        String :username
        String :password
        String :database_name
        String :table_name
        String :primary_key, :default => "id"
        String :status
        Integer :project_id
        Time :transformed_at
        Time :created_at
        Time :updated_at
      end

      @database.create_table :transformations do
        primary_key :id
        String :field_name
        String :transformer_name
        Integer :resource_id
        Time :created_at
        Time :updated_at
      end

      @database.create_table :scenarios do
        primary_key :id
        String :name
        String :description
        String :type
        String :status
        Integer :project_id
        Time :run_at
        Time :created_at
        Time :updated_at
      end

      @database.create_table :resources_scenarios do
        primary_key :id
        Integer :resource_id
        Integer :scenario_id
        Time :created_at
        Time :updated_at
      end

      @database.create_table :matchers do
        primary_key :id
        String :field
        String :comparator_name
        Text :comparator_options
        Integer :scenario_id
        Time :created_at
        Time :updated_at
      end

      #@database.create_table :jobs do
        #primary_key :id
        #Integer :resource_id
        #String :type
        #Integer :completed
        #Integer :total
        #String :status
        #String :message
        #Time :created_at
        #Time :updated_at
      #end
    end
  end
end
