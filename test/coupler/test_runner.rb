require File.dirname(__FILE__) + "/../helper"

module Coupler
  class TestRunner < Test::Unit::TestCase
    def setup
      super
      @server = stub("server", :is_running? => true, :start => nil)
      Server.stubs(:instance).returns(@server)
      @scheduler = stub("scheduler", :is_started? => true, :start => nil)
      Scheduler.stubs(:instance).returns(@scheduler)
      @database = stub("database", :migrate! => nil)
      Database.stubs(:instance).returns(@database)
      Base.stubs(:run!)
    end

    def test_starts_server
      @server.stubs(:is_running?).returns(false)
      @server.expects(:start)
      Runner.new([])
    end

    def test_stops_server_if_started
      @server.stubs(:is_running?).returns(false)
      @server.expects(:shutdown)
      Base.expects(:run!).yields(stub())
      Runner.new([])
    end

    def test_starts_scheduler
      @scheduler.stubs(:is_started?).returns(false)
      @scheduler.expects(:start)
      Runner.new([])
    end

    def test_stops_scheduler_if_started
      @scheduler.stubs(:is_started?).returns(false)
      @scheduler.expects(:shutdown)
      Base.expects(:run!).yields(stub())
      Runner.new([])
    end

    def test_migrates_the_database
      @database.expects(:migrate!)
      Runner.new([])
    end

    def test_sets_web_port
      argv = %w{--port=37222}
      Base.expects(:set).with(:port, 37222)
      Runner.new(argv)
    end

    def test_sets_database_port
      argv = %w{--dport=31337}
      Config.expects(:set).with(:database, :port, 31337)
      Runner.new(argv)
    end
  end
end
