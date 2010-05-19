module Coupler
  module Config
    DEFAULT_CONFIG = {
      :database => {
        :port => 12345,
        :user => 'coupler',
        :password => 'cupla',
        :conn_str => 'jdbc:mysql://localhost:%d/%s?user=%s&password=%s'
      }
    }

    VENDOR_LIBS = {
      'mysql-connector-mxj' => {
        :type => 'java',
        :filetype => "tarball",
        :version => '5-0-11',
        :dir => "mysql-connector-mxj-gpl-%s",
        :url => "ftp://mirror.anl.gov/pub/mysql/Downloads/Connector-MXJ/mysql-connector-mxj-gpl-%s.tar.gz",
        :libs => [
          "mysql-connector-mxj-gpl-%s.jar",
          "mysql-connector-mxj-gpl-%s-db-files.jar"
        ]
      },
      'mysql-connector-java' => {
        :type => 'java',
        :filetype => "tarball",
        :version => '5.1.12',
        :dir => "mysql-connector-java-%s",
        :url => "ftp://mirror.anl.gov/pub/mysql/Downloads/Connector-J/mysql-connector-java-%s.tar.gz",
        :libs => [
          "mysql-connector-java-%s-bin.jar",
        ]
      },
      'one-jar' => {
        :type => 'java',
        :filetype => "jar",
        :version => '0.96',
        :dir => "one-jar-%s",
        :url => "http://downloads.sourceforge.net/one-jar/one-jar-sdk-%s.jar?modtime=1190046700&big_mirror=0"
      },
      'quartz' => {
        :type => 'java',
        :filetype => 'zip',
        :version => '1.6.6',
        :dir => "quartz-%s",
        :url => "http://www.quartz-scheduler.org/download/quartz-%s.zip",
        :libs => [
          'quartz-%s.jar',
          File.join('lib', 'core', 'commons-logging-1.1.jar')
        ]
      }
    }

    def self.each_vendor_lib
      VENDOR_LIBS.each_pair do |name, info|
        yield(name, info[:type], info[:filetype], info[:dir] % info[:version], info[:url] % info[:version])
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

      if keys == [:data_path] && !@@config.has_key?(keys[0])
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
        dir = File.expand_path(dir)
        Dir.mkdir(dir)  if !File.exist?(dir)
        @@config[:data_path] = dir
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
      retval = self.get(:database, :conn_str) % [self.get(:database, :port), database, self.get(:database, :user), self.get(:database, :password)]
      retval += "&createDatabaseIfNotExist=true"  if options[:create_database]
      case options[:zero_date_time_behavior]
      when :convert_to_null
        retval += "&zeroDateTimeBehavior=convertToNull"
      end
      retval
    end
  end
end
