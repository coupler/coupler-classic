module Coupler
  class Database < Delegator
    include Singleton

    def initialize
      @env = ENV['COUPLER_ENV']
      database_name = @env ? "coupler_#{@env}" : "coupler"
      connection_string = Config.connection_string(database_name, :create_database => true)
      @database = Sequel.connect(connection_string, :loggers => [Coupler::Logger.instance], :max_connections => 12)
      super(@database)

      migrate!
    end

    def __getobj__
      @database
    end

    def migrate!
      if @env == "test"
        # FIXME: this isn't really the best solution
        Sequel::MySQL.default_engine = "InnoDB"
      end

      dir = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'db', 'migrate'))
      Sequel::Migrator.apply(@database, dir)
    end
  end
end

Coupler::Database.instance
