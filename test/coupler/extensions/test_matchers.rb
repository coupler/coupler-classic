require File.dirname(__FILE__) + '/../../helper'

module Coupler
  module Extensions
    class TestMatchers < Test::Unit::TestCase
      def setup
        super
        @project = Factory(:project)
        @resource = Factory(:resource, :project => @project)
        @scenario = Factory(:scenario, :project => @project, :resource_1 => @resource)
      end

      def test_new
        get "/projects/#{@project.id}/scenarios/#{@scenario.id}/matchers/new"
        assert last_response.ok?
      end

      def test_successfully_creating_matcher
        attribs = {
          'comparator_name' => 'exact',
          'comparisons_attributes' => [{
            '0' => {
              'field_1_id' => @resource.fields_dataset[:name => 'first_name'].id,
              'field_2_id' => @resource.fields_dataset[:name => 'last_name'].id
            }
          }]
        }
        post("/projects/#{@project.id}/scenarios/#{@scenario.id}/matchers", { 'matcher' => attribs })
        assert last_response.redirect?, "Wasn't redirected"
        assert_equal "/projects/#{@project.id}/scenarios/#{@scenario.id}", last_response['location']

        matcher = @scenario.matchers_dataset.first
        assert matcher
      end

      def test_edit
        matcher = Factory(:matcher, :scenario => @scenario)
        field_1 = @resource.fields[1]
        field_2 = @resource.fields[2]
        comparison = Factory(:comparison, :matcher => matcher, :field_1 => field_1, :field_2 => field_2)
        get "/projects/#{@project.id}/scenarios/#{@scenario.id}/matchers/#{matcher.id}/edit"
        assert last_response.ok?
      end

      def test_updating_matcher
        matcher = Factory(:matcher, :scenario => @scenario)
        field_1 = @resource.fields[1]
        field_2 = @resource.fields[2]
        comparison = Factory(:comparison, :matcher => matcher, :field_1 => field_1, :field_2 => field_2)

        attribs = {'comparisons_attributes' => [
          { 'id' => comparison.id, '_delete' => true },
          { 'field_1_id' => field_2.id, 'field_2_id' => field_1.id }
        ]}
        put "/projects/#{@project.id}/scenarios/#{@scenario.id}/matchers/#{matcher.id}", :matcher => attribs

        assert last_response.redirect?, "Wasn't redirected"
        assert_equal "/projects/#{@project.id}/scenarios/#{@scenario.id}", last_response['location']
      end

      def test_delete
        matcher = Factory(:matcher, :scenario => @scenario)
        delete "/projects/#{@project.id}/scenarios/#{@scenario.id}/matchers/#{matcher.id}"
        assert_equal 0, Models::Matcher.filter(:id => matcher.id).count

        assert last_response.redirect?, "Wasn't redirected"
        assert_equal "/projects/#{@project.id}/scenarios/#{@scenario.id}", last_response['location']
      end
    end
  end
end
