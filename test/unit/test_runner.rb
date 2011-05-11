require 'helper'

module Coupler
  class TestRunner < Coupler::Test::UnitTest
    def setup
      super
      @scheduler = stub("scheduler", :is_started? => true, :start => nil)
      Scheduler.stubs(:instance).returns(@scheduler)
      @database = stub("database", :migrate! => nil)
      Database.stubs(:instance).returns(@database)
      @app = stub('rack app')
      @handler = stub('rack handler', :new => @app)
      Rack::Handler.stubs(:get).returns(@handler)
      @thread = stub('mongrel thread', :join => nil)
      @mongrel = stub('mongrel', :register => nil, :run => @thread)
      Mongrel::HttpServer.stubs(:new).returns(@mongrel)
      @settings = stub('settings', :bind => '0.0.0.0', :port => 123)
      Base.stubs(:set => nil, :settings => @settings)
    end

    def capture_stdout
      begin
        out = StringIO.new
        $stdout = out
        yield
        return out
      ensure
        $stdout = STDOUT
      end
    end

    test "starts scheduler" do
      @scheduler.expects(:start)
      capture_stdout { Runner.new([]) }
    end

    test "starts web server" do
      Mongrel::HttpServer.expects(:new).with('0.0.0.0', 123, 950, 0, 60).returns(@mongrel)
      @handler.expects(:new).with(Coupler::Base).returns(@app)
      @mongrel.expects(:register).with('/', @app)
      @mongrel.expects(:run).returns(@thread)
      Coupler::Base.expects(:set).with(:running, true)
      capture_stdout { Runner.new([]) }
    end

    test "shutting down" do
      @scheduler.expects(:shutdown)
      @mongrel.expects(:stop)
      capture_stdout { r = Runner.new([]); r.shutdown }
    end

    test "migrates the database" do
      @database.expects(:migrate!)
      capture_stdout { Runner.new([]) }
    end

    test "sets web port" do
      argv = %w{--port=37222}
      Base.expects(:set).with(:port, 37222)
      capture_stdout { Runner.new(argv) }
    end

    test "sets data path" do
      argv = %w{--dir=/tmp/coupler}
      Base.expects(:set).with(:data_path, '/tmp/coupler')
      capture_stdout { Runner.new(argv) }
    end

    test "sets environment" do
      argv = %w{--environment=development}
      Base.expects(:set).with(:environment, :development)
      capture_stdout { Runner.new(argv) }
    end

    test "joining web server" do
      r = nil
      capture_stdout { r = Runner.new([]) }
      @thread.expects(:join)
      r.join
    end

    test "message proc" do
      messages = []
      Runner.new([]) do |msg|
        messages << msg
      end
      assert !messages.empty?
    end
  end
end
