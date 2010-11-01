require File.dirname(__FILE__) + '/../../helper'

module Coupler
  module Extensions
    class TestTransformers < Test::Unit::TestCase
      def test_index
        get '/transformers'
        assert last_response.ok?
      end

      def test_new
        get '/transformers/new'
        assert last_response.ok?
      end

      def test_successful_create
        count = Models::Transformer.count
        post '/transformers', 'transformer' => Factory.attributes_for(:transformer)
        assert_equal count + 1, Models::Transformer.count
        assert last_response.redirect?
        assert_equal "/transformers", last_response['location']
      end

      def test_failed_create
        count = Models::Transformer.count
        post '/transformers', 'transformer' => Factory.attributes_for(:transformer, :name => nil)
        assert_equal count, Models::Transformer.count
        assert last_response.ok?
      end

      def test_edit
        xformer = Factory(:transformer)
        get "/transformers/#{xformer.id}/edit"
        assert last_response.ok?
      end

      def test_successful_update
        xformer = Factory(:transformer)
        put "/transformers/#{xformer.id}", :transformer => { 'code' => 'value' }
        assert last_response.redirect?, last_response.inspect
        assert_equal "/transformers", last_response['location']
      end

      def test_failed_update
        xformer = Factory(:transformer)
        put "/transformers/#{xformer.id}", :transformer => { 'code' => 'foo(' }
        assert last_response.ok?
      end

      def test_preview
        post "/transformers/preview", :transformer => { 'code' => 'value.downcase', 'allowed_types' => %w{string}, 'result_type' => 'string' }
        assert last_response.ok?
      end

      def test_delete
        xformer = Factory(:transformer)
        delete "/transformers/#{xformer.id}"
        assert_equal 0, Models::Transformer.filter(:id => xformer.id).count
        assert last_response.redirect?, last_response.inspect
        assert_equal "/transformers", last_response['location']
      end

      def test_show
        xformer = Factory(:transformer)
        get "/transformers/#{xformer.id}"
        assert last_response.ok?
      end
    end
  end
end
