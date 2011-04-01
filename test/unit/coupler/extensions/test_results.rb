require File.dirname(__FILE__) + '/../../helper'

module Coupler
  module Extensions
    class TestResults < Test::Unit::TestCase
      class << self
        def startup
          super
          load_table_set(:basic_cross_linkage)
        end

        def shutdown
          unload_table_set(:basic_cross_linkage)
          super
        end
      end

      def setup
        super
        @project = Factory(:project)
        @resource = Factory(:resource, :database_name => 'coupler_test_data', :table_name => 'records', :project => @project)
        @scenario = Factory(:scenario, :project => @project, :resource_1 => @resource)
        @matcher = Factory(:matcher, {
          :scenario => @scenario,
          :comparisons_attributes => [{
            'lhs_type' => 'field', 'raw_lhs_value' => @resource.fields_dataset[:name => 'uno_col'].id, 'lhs_which' => 1,
            'rhs_type' => 'field', 'raw_rhs_value' => @resource.fields_dataset[:name => 'dos_col'].id, 'rhs_which' => 2,
            'operator' => 'equals'
          }]
        })
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
        group_id = nil
        @result.groups_dataset { |ds| group_id = ds.get(:id) }
        get "/projects/#{@project.id}/scenarios/#{@scenario.id}/results/#{@result.id}/details/#{group_id}"
        assert last_response.ok?
      end

      def test_show_sends_csv
        Models::Result.any_instance.expects(:to_csv).returns("foo,bar\n1,2")
        get "/projects/#{@project.id}/scenarios/#{@scenario.id}/results/#{@result.id}.csv"
        assert_equal %{attachment; filename="#{@scenario.slug}-run-#{@result.created_at.strftime('%Y%m%d-%H%M')}.csv"}, last_response['Content-Disposition']

        body = last_response.body
        #if md = body.match(/^(.+?)\n\n/m)
          #metadata = md[1]
          #body = body[md.end(0)..-1]
        #else
          #flunk "No metadata found"
        #end
        assert_equal "foo,bar\n1,2", body
      end

      def test_show_with_non_existant_result
        get "/projects/#{@project.id}/scenarios/#{@scenario.id}/results/8675309"
        assert last_response.redirect?
        assert_equal "http://example.org/projects/#{@project.id}/scenarios/#{@scenario.id}/results", last_response['location']
        follow_redirect!
        assert_match /The result you were looking for doesn't exist/, last_response.body
      end
    end
  end
end
