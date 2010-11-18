require File.dirname(__FILE__) + '/../helper'

module Coupler
  class TestBase < Test::Unit::TestCase
    def test_subclasses_sinatra_base
      assert_equal Sinatra::Base, Coupler::Base.superclass
    end

    def test_index_when_no_projects
      get "/"
      assert last_response.ok?
      assert_match /Getting Started/, last_response.body
    end

    def test_redirect_when_projects_exist
      project = Factory(:project)
      get "/"
      assert last_response.redirect?
      assert_equal "http://example.com/projects", last_response['location']
    end
  end
end
