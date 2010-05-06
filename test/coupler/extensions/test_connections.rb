require File.dirname(__FILE__) + '/../../helper'

module Coupler
  module Extensions
    class TestConnections < Test::Unit::TestCase
      def test_index
        connection = Factory(:connection)
        get "/connections"
        assert last_response.ok?
      end

      def test_new
        get "/connections/new"
        assert last_response.ok?

        doc = Nokogiri::HTML(last_response.body)
        assert_equal 1, doc.css("form[action='/connections']").length
        assert_equal 1, doc.css("select[name='connection[adapter]']").length
        %w{name host port username password database_name}.each do |name|
          assert_equal 1, doc.css("input[name='connection[#{name}]']").length
        end
      end

      def test_successfully_creating_connection
        attribs = Factory.attributes_for(:connection)
        post "/connections", { 'connection' => attribs }
        connection = Models::Connection[:name => attribs[:name]]
        assert connection

        assert last_response.redirect?, "Wasn't redirected"
        assert_equal "/connections", last_response['location']
      end

      def test_successfully_creating_connection_with_return_to
        attribs = Factory.attributes_for(:connection)
        post "/connections", { 'connection' => attribs }, { 'rack.session' => { :return_to => '/foo' } }
        connection = Models::Connection[:name => attribs[:name]]
        assert connection

        assert last_response.redirect?, "Wasn't redirected"
        assert_equal "/foo", last_response['location']
      end

      def test_failing_to_create_connection
        post "/connections", {
          'connection' => Factory.attributes_for(:connection, :name => nil)
        }
        assert last_response.ok?
        assert_match /Name is required/, last_response.body
      end
    end
  end
end
