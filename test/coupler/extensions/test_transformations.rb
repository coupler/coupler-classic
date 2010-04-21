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
        fields = doc.at('select[name="transformation[field_name]"]')
        assert_equal %w{id first_name last_name}, fields.css('option').collect(&:inner_html)

        transformers = doc.at('select[name="transformation[transformer_name]"]')
        assert_equal [@transformer.name],
          transformers.css('option').collect(&:inner_html)
      end

      def test_successfully_creating_transformation
        xformer = Factory(:transformer)
        attribs = Factory.attributes_for(:transformation)
        attribs[:transformer_id] = xformer.id
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
        xformer = Factory(:transformer, :name => "downcaser")
        t12n = Factory(:transformation, :resource => @resource, :field_name => "first_name", :transformer => xformer)

        get "/projects/#{@project.id}/resources/#{@resource.id}/transformations/for/first_name"
        assert_match /downcaser/, last_response.body
      end

      def test_index
        t12n = Factory(:transformation, :resource => @resource, :field_name => "first_name")
        get "/projects/#{@project.id}/resources/#{@resource.id}/transformations"
        assert last_response.ok?
      end
    end
  end
end
