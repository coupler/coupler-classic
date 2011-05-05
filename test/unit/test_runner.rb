require 'helper'

module Coupler
  class TestRunner < Coupler::Test::UnitTest
    def setup
      super
      #@server = stub("server", :is_running? => true, :start => nil)
      #Server.stubs(:instance).returns(@server)
      @scheduler = stub("scheduler", :is_started? => true, :start => nil)
      Scheduler.stubs(:instance).returns(@scheduler)
      @database = stub("database", :migrate! => nil)
      Database.stubs(:instance).returns(@database)
      Base.stubs(:run!)
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

    def test_sets_data_path
      argv = %w{--dir=/tmp/coupler}
      Base.expects(:set).with(:data_path, '/tmp/coupler')
      Runner.new(argv)
    end

    def test_sets_environment
      argv = %w{--environment=development}
      Base.expects(:set).with(:environment, :development)
      Runner.new(argv)
    end
  end
end
