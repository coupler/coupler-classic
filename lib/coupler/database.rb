module Coupler
  class Database < Delegator
    include Singleton

    def initialize
      @env = ENV['COUPLER_ENV']
      database_name = @env ? "coupler_#{@env}" : "coupler"
      connection_string = Config.connection_string(database_name, :create_database => true)
      @database = Sequel.connect(connection_string, :loggers => [Coupler::Logger.instance], :max_connections => 12)
      super(@database)

      if @database.tables.empty?
        create_schema
      end
    end

    def __getobj__
      @database
    end

    def create_schema
      if @env == "test"
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
        String :slug
        String :description
        String :type
        Integer :project_id
        Integer :score_set_id
        Time :last_run_at
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
        String :comparator_name
        Text :comparator_options
        Integer :scenario_id
        Time :created_at
        Time :updated_at
      end
    end
  end
end

Coupler::Database.instance
