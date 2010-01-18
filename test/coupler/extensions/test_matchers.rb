require File.dirname(__FILE__) + '/../../helper'

module Coupler
  module Extensions
    class TestMatchers < ActiveSupport::TestCase
      def setup
        @project = Factory(:project, :slug => "roflcopter")
        @scenario = Factory(:scenario, :project => @project)
      end

      def test_new
        get "/projects/roflcopter/scenarios/#{@scenario.id}/matchers/new"
        assert last_response.ok?
      end

      def test_successfully_creating_matcher
        attribs = Factory.attributes_for(:matcher, :comparator_options => {"field_name" => "first_name"})
        post("/projects/roflcopter/scenarios/#{@scenario.id}/matchers", { 'matcher' => attribs })
        assert last_response.redirect?, "Wasn't redirected"
        follow_redirect!
        assert_equal "http://example.org/projects/roflcopter/scenarios/#{@scenario.id}", last_request.url

        matcher = @scenario.matchers_dataset.first
        assert matcher
        assert_equal({"field_name" => "first_name"}, matcher.comparator_options)
      end

      def test_creating_without_comparator_options
        attribs = Factory.attributes_for(:matcher, :comparator_options => nil)
        post("/projects/roflcopter/scenarios/#{@scenario.id}/matchers", { 'matcher' => attribs })
        assert last_response.redirect?, "Wasn't redirected"
        follow_redirect!
        assert_equal "http://example.org/projects/roflcopter/scenarios/#{@scenario.id}", last_request.url

        matcher = @scenario.matchers_dataset.first
        assert matcher
      end
    end
  end
end
