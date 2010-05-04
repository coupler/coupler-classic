require File.dirname(__FILE__) + '/../../helper'

module Coupler
  module Extensions
    class TestTransformations < Test::Unit::TestCase
      def setup
        super
        @project = Factory(:project)
        @resource = Factory(:resource, :project => @project)
        @transformer = Factory(:transformer)
      end

      def test_new
        get "/projects/#{@project.id}/resources/#{@resource.id}/transformations/new"
        assert last_response.ok?

        doc = Nokogiri::HTML(last_response.body)
        fields = doc.at('select[name="transformation[field_id]"]')
        assert_equal %w{id first_name last_name}, fields.css('option').collect(&:inner_html)

        transformers = doc.at('select[name="transformation[transformer_id]"]')
        assert_equal [@transformer.name],
          transformers.css('option').collect(&:inner_html)
      end

      def test_successfully_creating_transformation
        attribs = Factory.attributes_for(:transformation, {
          :transformer_id => @transformer.id,
          :field_id => @resource.fields.first.id
        })
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

      def test_for
        field = @resource.fields.first
        t12n = Factory(:transformation, :resource => @resource, :field => field, :transformer => @transformer)

        get "/projects/#{@project.id}/resources/#{@resource.id}/transformations/for/#{field.name}"
        assert_match /#{@transformer.name}/, last_response.body
      end

      def test_index
        field = @resource.fields.first
        t12n = Factory(:transformation, :resource => @resource, :field => field)
        get "/projects/#{@project.id}/resources/#{@resource.id}/transformations"
        assert last_response.ok?
      end
    end
  end
end
