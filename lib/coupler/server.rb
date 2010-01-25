# This needs to be standalone, since this needs to be running before the rest
# of Coupler is loaded.  The reason for this is that Sequel model classes (in
# Coupler::Models) will freak out if there is no connection established when
# the classes are initialized.
require 'java'
require 'singleton'
require 'jdbc/mysql'

# mysql embedded
dir = File.join(File.dirname(__FILE__), "..", "..", "vendor", "mysql-connector-mxj-gpl-5-0-9")
require File.join(dir, "mysql-connector-mxj-gpl-5-0-9.jar")
require File.join(dir, "mysql-connector-mxj-gpl-5-0-9-db-files.jar")
require File.join(dir, "lib", "aspectjrt.jar")

module Coupler
  class Server
    include Singleton

    if !self.const_defined?(:CONFIG)
      CONFIG = {
        :port => 12345,
        :user => 'coupler',
        :password => 'cupla',
        :conn_str => 'jdbc:mysql://localhost:%d/%s?user=%s&password=%s'
      }
    end

    @@base_dir = nil
    def self.base_dir
      # FIXME: this is a little naive

      if @@base_dir.nil?
        dir = File.join(File.dirname(__FILE__), "..", "..", "db")
        if ENV['APPDATA']
          # Windows
          dir = File.join(ENV['APPDATA'], "coupler")
        elsif !File.readable?(dir)
          if ENV['HOME']
            dir = File.join(ENV['HOME'], ".coupler")
          else
            raise "don't know where to put the database!"
          end
        end
        dir = File.expand_path(dir)
        Dir.mkdir(dir)  if !File.exist?(dir)
        @@base_dir = dir
      end

      @@base_dir
    end

    def initialize
      dir = java.io.File.new(self.class.base_dir)
      @server = com.mysql.management.MysqldResource.new(dir)
    end

    def start
      if !@server.is_running
        options = java.util.HashMap.new({
          'port'                     => CONFIG[:port].to_s,
          'initialize-user'          => 'true',
          'initialize-user.user'     => CONFIG[:user],
          'initialize-user.password' => CONFIG[:password]
        })
        @server.start("coupler-server", options)
      end
    end

    def shutdown
      @server.shutdown    if @server.is_running
    end

    def console
      if @server.is_running
        puts "mysql -P #{CONFIG[:port]} -u #{CONFIG[:user]} --password=#{CONFIG[:password]} -S #{File.join(self.class.base_dir, "data", "mysql.sock")}"
        true
      else
        false
      end
    end

    def connection_string(database, options = {})
      retval = CONFIG[:conn_str] % [CONFIG[:port], database, CONFIG[:user], CONFIG[:password]]
      if options[:create_database]
        retval += "&createDatabaseIfNotExist=true"
      end
      retval
    end

    def is_running?
      @server.is_running
    end
  end
end
