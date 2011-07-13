module Coupler
  Database = Sequel.connect(Coupler.connection_string('coupler'), :loggers => [Coupler::Logger.instance], :max_connections => 20)
  class << Database
    def rollback!
      version = self[:schema_info].first[:version]
      migrate!(version - 1)
    end

    def migrate!(to = nil, from = nil)
      dir = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'db', 'migrate'))
      args = [self, dir]
      if to
        args << to
        args << from  if from
      end
      Sequel::Migrator.apply(*args)
    end

    def instance
      warn("DEPRECATION NOTICE: Database.instance")
      self
    end
  end
end
