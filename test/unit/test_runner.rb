require 'helper'

module CouplerUnitTests
  class TestRunner < Coupler::Test::UnitTest
    def setup
      super
      @scheduler = stub("scheduler", :is_started? => true, :start => nil)
      Scheduler.stubs(:instance).returns(@scheduler)
      Database.stubs(:migrate!)
      @server = stub('rack server', :start => nil)
      Rack::Server.stubs(:new).returns(@server)
      @settings = stub('settings', {
        :bind => '0.0.0.0', :port => 123,
        :environment => :test, :root => '/foo/bar'
      })
      @thread = stub('web thread')
      Thread.stubs(:new).yields.returns(@thread)
      Base.stubs(:set => nil, :settings => @settings)
      Runner.any_instance.stubs(:trap)
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
      Rack::Server.expects(:new).with({
        :host => '0.0.0.0', :port => 123, :environment => :test,
        :root => '/foo/bar', :app => Coupler::Base, :server => 'mizuno'
      }).returns(@server)
      @server.expects(:start)
      Coupler::Base.expects(:set).with(:running, true)
      capture_stdout { Runner.new([]) }
    end

    test "shutting down" do
      @scheduler.expects(:shutdown)
      @server.expects(:stop)
      capture_stdout { r = Runner.new([]); r.shutdown }
    end

    test "migrates the database" do
      Database.expects(:migrate!)
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
      capture_stdout do
        Runner.new([]) do |msg|
          messages << msg
        end
      end
      assert !messages.empty?
    end

    test "traps INT" do
      capture_stdout do
        Runner.any_instance.expects(:trap).with("INT")
        r = Runner.new([])
      end
    end

    test "doesn't trap INT" do
      capture_stdout do
        Runner.any_instance.expects(:trap).with("INT").never
        r = Runner.new([], :trap => false)
      end
    end
  end
end
