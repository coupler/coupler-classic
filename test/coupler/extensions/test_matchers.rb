require File.dirname(__FILE__) + '/../../helper'

module Coupler
  module Extensions
    class TestMatchers < ActiveSupport::TestCase
      def setup
        @project = Factory(:project)
        @scenario = Factory(:scenario, :project => @project)
      end

      def test_new
        get "/projects/#{@project.id}/scenarios/#{@scenario.id}/matchers/new"
        assert last_response.ok?
      end

      def test_successfully_creating_matcher
        attribs = Factory.attributes_for(:matcher, :comparator_options => {"field_name" => "first_name"})
        post("/projects/#{@project.id}/scenarios/#{@scenario.id}/matchers", { 'matcher' => attribs })
        assert last_response.redirect?, "Wasn't redirected"
        follow_redirect!
        assert_equal "http://example.org/projects/#{@project.id}/scenarios/#{@scenario.id}", last_request.url

        matcher = @scenario.matchers_dataset.first
        assert matcher
        assert_equal({"field_name" => "first_name"}, matcher.comparator_options)
      end

      def test_creating_without_comparator_options
        attribs = Factory.attributes_for(:matcher, :comparator_options => nil)
        post("/projects/#{@project.id}/scenarios/#{@scenario.id}/matchers", { 'matcher' => attribs })
        assert last_response.redirect?, "Wasn't redirected"
        follow_redirect!
        assert_equal "http://example.org/projects/#{@project.id}/scenarios/#{@scenario.id}", last_request.url

        matcher = @scenario.matchers_dataset.first
        assert matcher
      end

      def test_delete
        matcher = Factory(:matcher, :scenario => @scenario)
        delete "/projects/#{@project.id}/scenarios/#{@scenario.id}/matchers/#{matcher.id}"
        assert_equal 0, Models::Matcher.filter(:id => matcher.id).count

        assert last_response.redirect?, "Wasn't redirected"
        follow_redirect!
        assert_equal "http://example.org/projects/#{@project.id}/scenarios/#{@scenario.id}", last_request.url
      end
    end
  end
end
