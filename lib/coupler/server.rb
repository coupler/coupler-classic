# This needs to be standalone, since this needs to be running before the rest
# of Coupler is loaded.  The reason for this is that Sequel model classes (in
# Coupler::Models) will freak out if there is no connection established when
# the classes are initialized.

require 'java'
require 'singleton'
require 'jdbc/mysql'
require File.join(File.dirname(__FILE__), "config")

# mysql embedded
dir = File.join(File.dirname(__FILE__), "..", "..", "vendor", "mysql-connector-mxj-gpl-5-0-9")
require File.join(dir, "mysql-connector-mxj-gpl-5-0-9.jar")
require File.join(dir, "mysql-connector-mxj-gpl-5-0-9-db-files.jar")
require File.join(dir, "lib", "aspectjrt.jar")

module Coupler
  class Server
    include Singleton

    def initialize
      db_path = File.join(Config[:data_path], "db")
      Dir.mkdir(db_path)    if !File.exist?(db_path)

      file = java.io.File.new(db_path)
      @server = com.mysql.management.MysqldResource.new(file)
    end

    def start
      if !@server.is_running
        options = java.util.HashMap.new({
          'port'                     => Config[:port].to_s,
          'initialize-user'          => 'true',
          'initialize-user.user'     => Config[:user],
          'initialize-user.password' => Config[:password]
        })
        @server.start("coupler-server", options)
      end
    end

    def shutdown
      @server.shutdown    if @server.is_running
    end

    def console
      if @server.is_running
        puts "mysql -P #{Config[:port]} -u #{Config[:user]} --password=#{Config[:password]} -S #{File.join(self.class.base_dir, "data", "mysql.sock")}"
        true
      else
        false
      end
    end

    def is_running?
      @server.is_running
    end
  end
end
