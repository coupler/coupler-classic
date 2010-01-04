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
    end
  end
end
