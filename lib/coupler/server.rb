require 'jdbc/mysql'

base_dir = File.join(Coupler::ROOT, "vendor", "mysql-connector-mxj-gpl-5-0-9")
require File.join(base_dir, "mysql-connector-mxj-gpl-5-0-9.jar")
require File.join(base_dir, "mysql-connector-mxj-gpl-5-0-9-db-files.jar")
require File.join(base_dir, "lib", "aspectjrt.jar")

module Coupler
  class Server
    include Singleton

    PORT = 12345
    USER = 'coupler'
    PASSWORD = 'cupla'
    BASE_DIR = File.join(Coupler::ROOT, "db")
    CONN_STR = "jdbc:mysql://localhost:%d/%s?user=%s&password=%s"

    def initialize
      dir = java.io.File.new(BASE_DIR)
      @server = com.mysql.management.MysqldResource.new(dir)
    end

    def start
      if !@server.is_running
        options = java.util.HashMap.new({
          'port'                     => PORT.to_s,
          'initialize-user'          => 'true',
          'initialize-user.user'     => USER,
          'initialize-user.password' => PASSWORD
        })
        @server.start("coupler-server", options)
      end
    end

    def shutdown
      @server.shutdown    if @server.is_running
    end

    def console
      if @server.is_running
        puts "mysql -P #{PORT} -u #{USER} --password=#{PASSWORD} -S #{File.join(BASE_DIR, "data", "mysql.sock")}"
        true
      else
        false
      end
    end

    def connection_string(database, options = {})
      retval = CONN_STR % [PORT, database, USER, PASSWORD]
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
