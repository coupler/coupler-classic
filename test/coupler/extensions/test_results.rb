require File.dirname(__FILE__) + '/../../helper'

module Coupler
  module Extensions
    class TestResults < Test::Unit::TestCase
      class << self
        def startup
          ### Test Resource 1 ###
          Sequel.connect(Config.connection_string('test_resource_1', :create_database => true)) do |db|
            db.create_table!(:records) do
              primary_key :id
              String :uno_col
              String :dos_col
            end
            db[:records].import \
              [:id, :uno_col, :dos_col],
              [
                # Group 1
                [18, "foo", nil], [16, "foo", nil], [17, "foo", nil],
                [15, nil, "foo"], [13, nil, "foo"], [10, nil, "foo"], [19, nil, "foo"],
                # Group 2
                [25, "bar", nil], [23, "bar", nil], [20, "bar", nil], [29, "bar", nil],
                [28, nil, "bar"], [26, nil, "bar"], [27, nil, "bar"],
                # Group 3
                [38, "baz", nil],
                [35, nil, "baz"], [33, nil, "baz"], [30, nil, "baz"], [39, nil, "baz"],
                # Group 4
                [45, "quux", nil], [43, "quux", nil], [40, "quux", nil], [49, "quux", nil],
                [48, nil, "quux"],
                # Group 5
                [55, "ditto", "ditto"], [53, "ditto", "ditto"]
              ]
          end
        end
      end

      def setup
        super
        @project = Factory(:project)
        @resource = Factory(:resource, :database_name => 'test_resource_1', :table_name => 'records', :project => @project)
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
