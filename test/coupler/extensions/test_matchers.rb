require File.dirname(__FILE__) + '/../../helper'

module Coupler
  module Extensions
    class TestMatchers < Test::Unit::TestCase
      def setup
        super
        @project = Factory(:project)
        @resource = Factory(:resource, :project => @project)
        @first_name = @resource.fields_dataset[:name => 'first_name']
        @last_name = @resource.fields_dataset[:name => 'last_name']
        @scenario = Factory(:scenario, :project => @project, :resource_1 => @resource)
      end

      def test_new
        get "/projects/#{@project.id}/scenarios/#{@scenario.id}/matchers/new"
        assert last_response.ok?
      end

      def test_successfully_creating_matcher
        attribs = {
          'comparisons_attributes' => {
            '0' => {
              'lhs_type' => 'field', 'lhs_value' => @first_name.id.to_s,
              'rhs_type' => 'field', 'rhs_value' => @last_name.id.to_s,
              'operator' => 'equals'
            }
          }
        }
        post("/projects/#{@project.id}/scenarios/#{@scenario.id}/matchers", { 'matcher' => attribs })
        assert last_response.redirect?, "Wasn't redirected"
        assert_equal "/projects/#{@project.id}/scenarios/#{@scenario.id}", last_response['location']

        matcher = @scenario.matchers_dataset.first
        assert matcher
      end

      def test_edit
        matcher = Factory(:matcher, :scenario => @scenario)
        comparison = Factory(:comparison, {
          :matcher => matcher, :operator => 'equals',
          :lhs_type => 'field', :lhs_value => @first_name.id,
          :rhs_type => 'field', :rhs_value => @last_name.id
        })
        get "/projects/#{@project.id}/scenarios/#{@scenario.id}/matchers/#{matcher.id}/edit"
        assert last_response.ok?
      end

      def test_updating_matcher
        matcher = Factory(:matcher, :scenario => @scenario)
        comparison = Factory(:comparison, {
          :matcher => matcher, :operator => 'equals',
          :lhs_type => 'field', :lhs_value => @first_name.id,
          :rhs_type => 'field', :rhs_value => @last_name.id
        })

        attribs = {
          'comparisons_attributes' => {
            '0' => { 'id' => comparison.id, '_delete' => true },
            '1' => {
              'lhs_type' => 'field', 'lhs_value' => @last_name.id.to_s,
              'rhs_type' => 'field', 'rhs_value' => @first_name.id.to_s,
              'operator' => 'equals'
            }
          }
        }
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
