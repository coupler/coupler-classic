require 'helper'

module TestCoupler
  class TestApplication < Test::Unit::TestCase
    include Rack::Test::Methods
    include XhrHelper

    def app
      Coupler::Application
    end

    test "index" do
      get '/'
      assert last_response.ok?
    end

    test "files index" do
      file = stub('file', :filename => 'foo.txt')
      Coupler::File.expects(:all).returns([file])
      get '/files'
      assert last_response.ok?
    end

    test "file upload" do
      Dir.mktmpdir do |dir|
        fn = File.join(dir, 'foo.txt')
        File.open(fn, 'w') { |f| f.puts("foo") }
        upload = Rack::Test::UploadedFile.new(fn, 'text/plain')

        file = stub('file', :filename => 'foo.txt')
        Coupler::File.expects(:new).with({
          :data => "foo\n", :filename => 'foo.txt'
        }).returns(file)
        file.expects(:valid?).returns(true)
        file.expects(:save).returns(true)

        post '/files', :file => upload
        assert last_response.redirect?
        assert_equal "http://example.org/files", last_response['location']
      end
    end

    test "bad file upload" do
      Dir.mktmpdir do |dir|
        fn = File.join(dir, 'foo.txt')
        File.open(fn, 'w') { |f| f.puts("foo") }
        upload = Rack::Test::UploadedFile.new(fn, 'text/plain')

        file = stub('file', :filename => 'foo.txt')
        Coupler::File.expects(:new).with({
          :data => "foo\n", :filename => 'foo.txt'
        }).returns(file)
        file.expects(:valid?).returns(false)
        file.expects(:save).never

        post '/files', :file => upload
        assert last_response.redirect?
        assert_equal "http://example.org/files", last_response['location']
      end
    end
  end
end
