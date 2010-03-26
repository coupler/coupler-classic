require File.dirname(__FILE__) + '/../../helper'

module Coupler
  module Extensions
    class TestResults < Test::Unit::TestCase
      def setup
        super
        @project = Factory(:project)
        @resource = Factory(:resource, :project => @project)
        @scenario = Factory(:scenario, :project => @project, :resource_1 => @resource)
        @result = Factory(:result, :scenario => @scenario)
      end

      def test_index
        get "/projects/#{@project.id}/scenarios/#{@scenario.id}/results"
        assert last_response.ok?
      end

      def test_show_sends_csv
        ScoreSet.create do |score_set|
          @result.update(:score_set_id => score_set.id)
          score_set.insert(:first_id => 1, :second_id => 2, :score => 100)
        end

        get "/projects/#{@project.id}/scenarios/#{@scenario.id}/results/#{@result.id}"
        assert_equal %{attachment; filename="#{@scenario.slug}-run-#{@result.created_at.strftime('%Y%m%d%H%M')}.csv"}, last_response['Content-Disposition']
        assert_equal @result.to_csv, last_response.body
      end
    end
  end
end
