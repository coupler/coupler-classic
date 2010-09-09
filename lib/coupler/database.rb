module Coupler
  class Database < Delegator
    include Singleton

    def initialize
      @env = ENV['COUPLER_ENV']
      database_name = @env ? "coupler_#{@env}" : "coupler"
      connection_string = Config.connection_string(database_name, :create_database => true)
      @database = Sequel.connect(connection_string, :loggers => [Coupler::Logger.instance], :max_connections => 20)
      super(@database)
    end

    def __getobj__
      @database
    end

    def rollback!
      version = @database[:schema_info].first[:version]
      migrate!(version - 1)
    end

    def migrate!(to = nil, from = nil)
      if @env == "test"
        # FIXME: this isn't really the best solution
        Sequel::MySQL.default_engine = "InnoDB"
      end

      dir = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'db', 'migrate'))
      args = [@database, dir]
      if to
        args << to
        args << from  if from
      end
      Sequel::Migrator.apply(*args)
    end
  end
end
