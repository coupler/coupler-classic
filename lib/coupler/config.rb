module Coupler
  module Config
    DEFAULT_CONFIG = {
      :database => {
        :port => 12345,
        :user => 'coupler',
        :password => 'cupla',
        :max_connections => '100',
        :max_allowed_packet => '1M',
        :connection_string => 'jdbc:mysql://localhost:%d/%s?user=%s&password=%s',
      }
    }

    VENDOR_LIBS = {
      'jruby' => {
        :type => 'java',
        :filetype => 'jar',
        :version => '1.5.2',
        :url => "http://repository.codehaus.org/org/jruby/jruby-complete/%1$s/jruby-complete-%1$s.jar",
        :uncompress => false,
        :filename => "jruby-complete-%s.jar",
        :symlink => "jruby-complete.jar"
      },
      'mysql-connector-mxj' => {
        :type => 'java',
        :filetype => "tarball",
        :version => '5-0-11',
        :dir => "mysql-connector-mxj-gpl-%s",
        :url => "http://mysql.mirrors.hoobly.com/Downloads/Connector-MXJ/mysql-connector-mxj-gpl-%s.tar.gz",
        :libs => [
          "mysql-connector-mxj-gpl-%s.jar",
          "mysql-connector-mxj-gpl-%s-db-files.jar"
        ]
      },
      'mysql-connector-java' => {
        :type => 'java',
        :filetype => "tarball",
        :version => '5.1.13',
        :dir => "mysql-connector-java-%s",
        :url => "http://mysql.mirrors.hoobly.com/Downloads/Connector-J/mysql-connector-java-%s.tar.gz",
        :libs => [
          "mysql-connector-java-%s-bin.jar",
        ]
      }
    }

    def self.each_vendor_lib
      VENDOR_LIBS.each_pair do |name, info|
        info = info.merge({:url => info[:url] % info[:version]})
        info[:dir]      %= info[:version]   if info[:dir]
        info[:filename] %= info[:version]   if info[:filename]
        yield(name, info)
      end
    end

    def self.require_vendor_libs(name)
      info = VENDOR_LIBS[name]
      version = info[:version]
      path = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'vendor', info[:type], info[:dir] % version))
      info[:libs].each do |lib|
        require File.join(path, lib % version)
      end
    end

    @@config = nil
    def self.get(*keys)
      if @@config.nil?
        @@config = DEFAULT_CONFIG
      end

      if keys == [:data_path]
        if !@@config.has_key?(keys[0])
          # FIXME: this is a little naive
          dir = File.join(File.dirname(__FILE__), "..", "..")
          if ENV['APPDATA']
            # Windows
            dir = File.join(ENV['APPDATA'], "coupler")
          elsif !File.writable?(dir)
            if ENV['HOME']
              dir = File.join(ENV['HOME'], ".coupler")
            else
              raise "don't know where to put data!"
            end
          end
          @@config[:data_path] = File.expand_path(dir)
        end
        Dir.mkdir(@@config[:data_path])   if !File.exist?(@@config[:data_path])
      elsif keys == [:upload_path]
        if !@@config.has_key?(keys[0])
          @@config[:upload_path] = path = File.join(get(:data_path), "uploads")
        end
        Dir.mkdir(@@config[:upload_path]) if !File.exist?(@@config[:upload_path])
      end

      keys.inject(@@config) { |hash, key| hash[key] }
    end

    def self.set(*args)
      if @@config.nil?
        @@config = DEFAULT_CONFIG
      end

      value = args.pop
      keys = args

      hash = keys[0..-2].inject(@@config) { |h, k| h[k] }
      hash[keys[-1]] = value
    end

    def self.connection_string(database, options = {})
      retval = self.get(:database, :connection_string) % [self.get(:database, :port), database, self.get(:database, :user), self.get(:database, :password)]
      retval += "&createDatabaseIfNotExist=true"  if options[:create_database]
      case options[:zero_date_time_behavior]
      when :convert_to_null
        retval += "&zeroDateTimeBehavior=convertToNull"
      end
      retval += "&autoReconnect=true"  if options[:auto_reconnect]
      retval
    end
  end
end
