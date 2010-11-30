require File.dirname(__FILE__) + '/../../helper'

module Coupler
  module Extensions
    class TestResults < Test::Unit::TestCase
      def setup
        super
        @project = Factory(:project)
        @resource = Factory(:resource, :project => @project)
        @scenario = Factory(:scenario, :project => @project, :resource_1 => @resource)
        @matcher = Factory(:matcher, :scenario => @scenario)
        @scenario.run!
        @result = @scenario.results_dataset.first
      end

      def test_index
        get "/projects/#{@project.id}/scenarios/#{@scenario.id}/results"
        assert last_response.ok?
      end

      def test_index_with_non_existant_project
        get "/projects/8675309/scenarios/#{@scenario.id}/results"
        assert last_response.redirect?
        assert_equal "http://example.org/projects", last_response['location']
        follow_redirect!
        assert_match /The project you were looking for doesn't exist/, last_response.body
      end

      def test_index_with_non_existant_scenario
        get "/projects/#{@project.id}/scenarios/8675309/results"
        assert last_response.redirect?
        assert_equal "http://example.org/projects/#{@project.id}/scenarios", last_response['location']
        follow_redirect!
        assert_match /The scenario you were looking for doesn't exist/, last_response.body
      end

      def test_show
        get "/projects/#{@project.id}/scenarios/#{@scenario.id}/results/#{@result.id}"
        assert last_response.ok?
      end

      def test_details
        pend "Need decent results fixtures to test this properly"
        get "/projects/#{@project.id}/scenarios/#{@scenario.id}/results/#{@result.id}/details/123"
        assert last_response.ok?
      end

=begin
      def test_show_sends_csv
        pend
        ScoreSet.create do |score_set|
          @result.update(:score_set_id => score_set.id)
          score_set.insert(:first_id => 1, :second_id => 2, :score => 100)
        end

        get "/projects/#{@project.id}/scenarios/#{@scenario.id}/results/#{@result.id}"
        assert_equal %{attachment; filename="#{@scenario.slug}-run-#{@result.created_at.strftime('%Y%m%d-%H%M')}.txt"}, last_response['Content-Disposition']

        body = last_response.body
        if md = body.match(/^(.+?)\n\n/m)
          metadata = md[1]
          body = body[md.end(0)..-1]
        else
          flunk "No metadata found"
        end
        assert_equal @result.to_csv, body
      end

      def test_show_with_non_existant_result
        get "/projects/#{@project.id}/scenarios/#{@scenario.id}/results/8675309"
        assert last_response.redirect?
        assert_equal "http://example.org/projects/#{@project.id}/scenarios/#{@scenario.id}/results", last_response['location']
        follow_redirect!
        assert_match /The result you were looking for doesn't exist/, last_response.body
      end
=end
    end
  end
end
