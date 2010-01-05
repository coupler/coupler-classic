require File.dirname(__FILE__) + '/../../helper'

module Coupler
  module Extensions
    class TestScenarios < ActiveSupport::TestCase
      def setup
        @project = Factory(:project, :slug => "roflcopter")
      end

      def test_show
        scenario = Factory(:scenario, :project => @project)
        get "/projects/roflcopter/scenarios/#{scenario.id}"
        assert last_response.ok?
      end

      def test_new
        get "/projects/roflcopter/scenarios/new"
        assert last_response.ok?
      end

      def test_successfully_creating_scenario
        resource = Factory(:resource, :project => @project)
        attribs = Factory.attributes_for(:scenario)
        post "/projects/roflcopter/scenarios", { 'scenario' => attribs, 'resource_ids' => [resource.id] }
        scenario = Models::Scenario[:name => attribs[:name], :project_id => @project.id]
        assert scenario
        assert_equal [resource], scenario.resources

        assert last_response.redirect?, "Wasn't redirected"
        follow_redirect!
        assert_equal "http://example.org/projects/roflcopter/scenarios/#{scenario.id}", last_request.url
      end

      def test_failing_to_create_scenario
        post "/projects/roflcopter/scenarios", {
          'scenario' => Factory.attributes_for(:scenario, :name => nil)
        }
        assert last_response.ok?
        assert_match /Name is required/, last_response.body
      end
    end
  end
end
