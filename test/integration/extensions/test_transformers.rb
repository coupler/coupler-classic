require 'helper'

module TestExtensions
  class TestTransformers < Coupler::Test::IntegrationTest
    test "index" do
      get '/transformers'
      assert last_response.ok?
    end

    test "new" do
      get '/transformers/new'
      assert last_response.ok?
    end

    test "successful create" do
      count = Transformer.count
      attribs = {
        :name => 'noop',
        :code => 'value',
        :allowed_types => %w{string},
        :result_type => 'string'
      }
      post '/transformers', 'transformer' => attribs
      assert_equal count + 1, Transformer.count
      assert last_response.redirect?
      assert_equal "http://example.org/transformers", last_response['location']
    end

    test "failed create" do
      count = Transformer.count
      attribs = {
        :name => '',
        :code => 'value',
        :allowed_types => %w{string},
        :result_type => 'string'
      }
      post '/transformers', 'transformer' => attribs
      assert_equal count, Transformer.count
      assert last_response.ok?
    end

    test "edit" do
      xformer = Transformer.create(:name => 'noop', :code => 'value', :allowed_types => %w{string}, :result_type => 'string')
      get "/transformers/#{xformer.id}/edit"
      assert last_response.ok?
    end

    test "successful update" do
      xformer = Transformer.create(:name => 'noop', :code => 'value', :allowed_types => %w{string}, :result_type => 'string')
      put "/transformers/#{xformer.id}", :transformer => { 'code' => 'value' }
      assert last_response.redirect?, last_response.inspect
      assert_equal "http://example.org/transformers", last_response['location']
    end

    test "failed update" do
      xformer = Transformer.create(:name => 'noop', :code => 'value', :allowed_types => %w{string}, :result_type => 'string')
      put "/transformers/#{xformer.id}", :transformer => { 'code' => 'foo(' }
      assert last_response.ok?
    end

    test "preview" do
      post "/transformers/preview", :transformer => { 'code' => 'value.downcase', 'allowed_types' => %w{string}, 'result_type' => 'string' }
      assert last_response.ok?
    end

    test "delete" do
      xformer = Transformer.create(:name => 'noop', :code => 'value', :allowed_types => %w{string}, :result_type => 'string')
      delete "/transformers/#{xformer.id}"
      assert_equal 0, Transformer.filter(:id => xformer.id).count
      assert last_response.redirect?, last_response.inspect
      assert_equal "http://example.org/transformers", last_response['location']
    end

    test "show" do
      xformer = Transformer.create(:name => 'noop', :code => 'value', :allowed_types => %w{string}, :result_type => 'string')
      get "/transformers/#{xformer.id}"
      assert last_response.ok?
    end
  end
end
