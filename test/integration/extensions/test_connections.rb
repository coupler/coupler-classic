require 'helper'

module TestExtensions
  class TestConnections < Coupler::Test::IntegrationTest
    def setup
      super
      @connections = []
      @configs = {}
      each_adapter do |adapter, config|
        conn = new_connection(adapter, :name => "#{adapter} connection").save!
        @connections << conn
        @configs[adapter] = config
      end
    end

    test "index" do
      get "/connections"
      assert last_response.ok?
    end

    test "new" do
      get "/connections/new"
      assert last_response.ok?

      doc = Nokogiri::HTML(last_response.body)
      assert_equal 1, doc.css("form[action='/connections']").length
      assert_equal 1, doc.css("select[name='connection[adapter]']").length
      %w{name host port username password}.each do |name|
        assert_equal 1, doc.css("input[name='connection[#{name}]']").length
      end
    end

    test "successfully creating connection" do
      attributes = @configs['mysql'].merge(:name => 'foo', :adapter => 'mysql')
      post "/connections", { 'connection' => attributes }
      connection = Connection[:name => 'foo']
      assert connection

      assert last_response.redirect?, "Wasn't redirected"
      assert_equal "http://example.org/connections", last_response['location']
    end

    test "successfully creating connection with return to" do
      attributes = @configs['mysql'].merge(:name => 'foo', :adapter => 'mysql')
      post "/connections", { 'connection' => attributes }, { 'rack.session' => { :return_to => '/foo' } }

      assert last_response.redirect?, "Wasn't redirected"
      assert_equal "http://example.org/foo", last_response['location']
    end

    test "successfully creating connection with first use" do
      attributes = @configs['mysql'].merge(:name => 'foo', :adapter => 'mysql')
      post "/connections", { 'connection' => attributes }, { 'rack.session' => { :first_use => true } }

      assert last_response.redirect?, "Wasn't redirected"
      assert_equal "http://example.org/projects/new", last_response['location']
    end

    test "failing to create connection" do
      attributes = @configs['mysql'].merge(:name => nil, :adapter => 'mysql')
      post "/connections", { 'connection' => attributes }
      assert last_response.ok?
      assert_match /Name is not present/, last_response.body
    end

    test "show" do
      @connections.each do |conn|
        get "/connections/#{conn.id}"
        assert last_response.ok?
      end
    end

    test "destroy" do
      delete "/connections/#{@connections[0].id}"
      assert_nil Models::Connection[@connections[0].id]
      assert last_response.redirect?
      assert_equal "http://example.org/connections", last_response['location']
    end
  end
end
