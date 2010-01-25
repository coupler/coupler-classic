if !defined? Coupler::Config
  module Coupler
    module Config
      DEFAULT_CONFIG = {
        :port => 12345,
        :user => 'coupler',
        :password => 'cupla',
        :conn_str => 'jdbc:mysql://localhost:%d/%s?user=%s&password=%s'
      }

      @@config = nil
      def self.[](key)
        if @@config.nil?
          @@config = DEFAULT_CONFIG
        end

        if !@@config.has_key?(key) && key == :data_path
          # FIXME: this is a little naive
          dir = File.join(File.dirname(__FILE__), "..", "..")
          if ENV['APPDATA']
            # Windows
            dir = File.join(ENV['APPDATA'], "coupler")
          elsif !File.readable?(dir)
            if ENV['HOME']
              dir = File.join(ENV['HOME'], ".coupler")
            else
              raise "don't know where to put data!"
            end
          end
          dir = File.expand_path(dir)
          Dir.mkdir(dir)  if !File.exist?(dir)
          @@config[key] = dir
        end

        @@config[key]
      end

      @@data_path = nil
      def self.data_path
        # FIXME: this is a little naive

        if @@data_path.nil?
          dir = File.join(File.dirname(__FILE__), "..", "..")
          if ENV['APPDATA']
            # Windows
            dir = File.join(ENV['APPDATA'], "coupler")
          elsif !File.readable?(dir)
            if ENV['HOME']
              dir = File.join(ENV['HOME'], ".coupler")
            else
              raise "don't know where to put data!"
            end
          end
          dir = File.expand_path(dir)
          Dir.mkdir(dir)  if !File.exist?(dir)
          @@data_path = dir
        end

        @@data_path
      end

      def self.connection_string(database, options = {})
        retval = self[:conn_str] % [self[:port], database, self[:user], self[:password]]
        if options[:create_database]
          retval += "&createDatabaseIfNotExist=true"
        end
        retval
      end
    end
  end
end
