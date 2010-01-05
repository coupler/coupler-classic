require File.dirname(__FILE__) + '/../../helper'

module Coupler
  module Models
    class TestScenario < ActiveSupport::TestCase
      def test_sequel_model
        assert_equal ::Sequel::Model, Scenario.superclass
        assert_equal :scenarios, Scenario.table_name
      end

      def test_many_to_one_project
        assert_respond_to Scenario.new, :project
      end

      def test_many_to_many_resources
        assert_respond_to Scenario.new, :resources
        resource = Factory(:resource)
        scenario = Factory(:scenario)
        resource.add_scenario(scenario)
        assert_equal [resource], scenario.resources
      end

      def test_one_to_many_matchers
        assert_respond_to Scenario.new, :matchers
      end

      def test_requires_name
        scenario = Factory.build(:scenario, :name => nil)
        assert !scenario.valid?

        scenario.name = ""
        assert !scenario.valid?
      end

      def test_requires_unique_name_across_projects
        project = Factory.create(:project)
        scenario_1 = Factory.create(:scenario, :name => "avast", :project => project)
        scenario_2 = Factory.build(:scenario, :name => "avast", :project => project)
        assert !scenario_2.valid?
      end

      def test_required_unique_name_on_update
        project = Factory.create(:project)
        scenario_1 = Factory.create(:scenario, :name => "avast", :project => project)
        scenario_2 = Factory.create(:scenario, :name => "ahoy", :project => project)
        scenario_1.name = "ahoy"
        assert !scenario_1.valid?, "Resource wasn't invalid"
      end

      def test_updating
        project = Factory.create(:project)
        scenario = Factory.create(:scenario, :name => "avast", :project => project)
        scenario.save!
      end
    end
  end
end
