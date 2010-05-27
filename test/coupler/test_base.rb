require File.dirname(__FILE__) + '/../helper'

module Coupler
  class TestBase < Test::Unit::TestCase
    def test_subclasses_sinatra_base
      assert_equal Sinatra::Base, Coupler::Base.superclass
    end

    def test_index_when_no_connections
      get "/"
      assert last_response.ok?
      assert_match /Getting Started/, last_response.body
    end

    def test_redirect_when_connections_exist
      conn = Factory(:connection)
      get "/"
      assert last_response.redirect?
      assert_equal "/projects", last_response['location']
    end
  end
end
