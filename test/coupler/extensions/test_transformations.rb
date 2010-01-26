require File.dirname(__FILE__) + '/../../helper'

module Coupler
  module Extensions
    class TestTransformations < ActiveSupport::TestCase
      def setup
        @project = ::Factory.create(:project)
        @resource = ::Factory.create(:resource, :project => @project)
      end

      def test_new
        get "/projects/#{@project.id}/resources/#{@resource.id}/transformations/new"
        assert last_response.ok?

        doc = Nokogiri::HTML(last_response.body)
        fields = doc.at('select[name="transformation[field_name]"]')
        assert_equal %w{id first_name last_name}, fields.css('option').collect(&:inner_html)

        transformers = doc.at('select[name="transformation[transformer_name]"]')
        assert_equal Transformers.list.keys.collect(&:to_s),
          transformers.css('option').collect(&:inner_html)
      end

      def test_successfully_creating_transformation
        attribs = Factory.attributes_for(:transformation)
        post("/projects/#{@project.id}/resources/#{@resource.id}/transformations", { 'transformation' => attribs })
        transformation = @resource.transformations_dataset.first
        assert transformation

        assert last_response.redirect?, "Wasn't redirected"
        follow_redirect!
        assert_equal "http://example.org/projects/#{@project.id}/resources/#{@resource.id}", last_request.url
      end

      def test_delete
        transformation = Factory(:transformation, :resource => @resource)
        delete "/projects/#{@project.id}/resources/#{@resource.id}/transformations/#{transformation.id}"
        assert_equal 0, Models::Transformation.filter(:id => transformation.id).count

        assert last_response.redirect?, "Wasn't redirected"
        follow_redirect!
        assert_equal "http://example.org/projects/#{@project.id}/resources/#{@resource.id}", last_request.url
      end
    end
  end
end
