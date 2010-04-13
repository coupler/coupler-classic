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

      [:projects, :projects_versions].each do |name|
        @database.create_table(name) do
          primary_key :id
          String :name
          String :slug
          String :description
          Integer :version, :default => 0
          Integer :current_id   if name.to_s =~ /_versions$/
          Time :created_at
          Time :updated_at
        end
      end

      [:resources, :resources_versions].each do |name|
        @database.create_table(name) do
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
          String :primary_key_name, :default => "id"
          Integer :project_id
          Integer :version, :default => 0
          Integer :current_id   if name.to_s =~ /_versions$/
          Time :transformed_at
          Time :created_at
          Time :updated_at
        end
      end

      [:transformers, :transformers_versions].each do |name|
        @database.create_table(name) do
          primary_key :id
          String :name
          Text :code
          String :allowed_types
          String :result_type
          Integer :version, :default => 0
          Integer :current_id   if name.to_s =~ /_versions$/
          Time :created_at
          Time :updated_at
        end
      end

      [:transformations, :transformations_versions].each do |name|
        @database.create_table(name) do
          primary_key :id
          String :field_name
          String :transformer_name
          Integer :resource_id
          Integer :version, :default => 0
          Integer :current_id   if name.to_s =~ /_versions$/
          Time :created_at
          Time :updated_at
        end
      end

      [:scenarios, :scenarios_versions].each do |name|
        @database.create_table(name) do
          primary_key :id
          String :name
          String :slug
          String :description
          Integer :project_id
          Integer :resource_1_id
          Integer :resource_2_id
          String :linkage_type
          Integer :score_set_id
          Integer :version, :default => 0
          Integer :current_id   if name.to_s =~ /_versions$/
          Time :last_run_at
          Time :created_at
          Time :updated_at
        end
      end

      [:matchers, :matchers_versions].each do |name|
        @database.create_table(name) do
          primary_key :id
          String :comparator_name
          Text :comparator_options
          Integer :scenario_id
          Integer :version, :default => 0
          Integer :current_id   if name.to_s =~ /_versions$/
          Time :created_at
          Time :updated_at
        end
      end

      @database.create_table :jobs do
        primary_key :id
        String :name
        String :status
        Integer :resource_id
        Integer :scenario_id
        Integer :total, :default => 0
        Integer :completed, :default => 0
        Time :created_at
        Time :updated_at
        Time :started_at
        Time :completed_at
      end

      @database.create_table :results do
        primary_key :id
        Integer :scenario_id
        Integer :scenario_version
        Integer :score_set_id
        Time :created_at
        Time :updated_at
      end
    end
  end
end

Coupler::Database.instance
