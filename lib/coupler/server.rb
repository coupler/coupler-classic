module Coupler
  class Server
    include Singleton

    def initialize
      db_path = File.join(Config.get(:data_path), "db")
      Dir.mkdir(db_path)    if !File.exist?(db_path)

      file = java.io.File.new(db_path)
      @server = com.mysql.management.MysqldResource.new(file)
    end

    def start
      if !@server.is_running
        options = java.util.HashMap.new({
          'port'                     => Config.get(:database, :port).to_s,
          'initialize-user'          => 'true',
          'initialize-user.user'     => Config.get(:database, :user),
          'initialize-user.password' => Config.get(:database, :password)
        })
        @server.start("coupler-server", options)
      end
    end

    def shutdown
      @server.shutdown    if @server.is_running
    end

    def console
      if @server.is_running
        puts "mysql -P #{Config.get(:database, :port)} -u #{Config.get(:database, :user)} --password=#{Config.get(:database, :password)} -S #{File.join(Config.get(:data_path), "db", "data", "mysql.sock")}"
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
