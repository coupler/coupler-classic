require 'helper'

module TestExtensions
  class TestTransformations < Coupler::Test::IntegrationTest
    def self.startup
      super
      conn = new_connection('h2', :name => 'foo')
      conn.database do |db|
        db.create_table!(:foo) do
          primary_key :id
          String :foo
          String :bar
        end
        db[:foo].insert({:foo => 'foo', :bar => 'bar'})
        db[:foo].insert({:foo => 'bar', :bar => 'foo'})
      end
    end

    def setup
      super
      @project = Project.create(:name => 'foo')
      @connection = new_connection('h2', :name => 'h2 connection').save!
      @resource = Resource.create(:name => 'foo', :project => @project, :connection => @connection, :table_name => 'foo')
      @transformer = Transformer.create(:name => 'noop', :code => 'value', :allowed_types => %w{string integer datetime}, :result_type => 'same')
    end

    test "new" do
      get "/projects/#{@project.id}/resources/#{@resource.id}/transformations/new"
      assert last_response.ok?
    end

    test "new with non existant project" do
      get "/projects/8675309/resources/#{@resource.id}/transformations/new"
      assert last_response.redirect?
      assert_equal "http://example.org/projects", last_response['location']
      follow_redirect!
      assert_match /The project you were looking for doesn't exist/, last_response.body
    end

    test "new with non existant resource" do
      get "/projects/#{@project.id}/resources/8675309/transformations/new"
      assert last_response.redirect?
      assert_equal "http://example.org/projects/#{@project.id}/resources", last_response['location']
      follow_redirect!
      assert_match /The resource you were looking for doesn't exist/, last_response.body
    end

    test "successfully creating transformation" do
      field = @resource.fields_dataset[:name => 'foo']
      attribs = {
        :transformer_id => @transformer.id.to_s,
        :source_field_id => field.id.to_s
      }
      post("/projects/#{@project.id}/resources/#{@resource.id}/transformations", { 'transformation' => attribs })
      transformation = @resource.transformations_dataset.first
      assert transformation

      assert last_response.redirect?, "Wasn't redirected"
      assert_equal "http://example.org/projects/#{@project.id}/resources/#{@resource.id}", last_response['location']
    end

    test "delete" do
      field = @resource.fields_dataset[:name => 'foo']
      transformation = Transformation.create!(:resource => @resource, :transformer => @transformer, :source_field => field)
      delete "/projects/#{@project.id}/resources/#{@resource.id}/transformations/#{transformation.id}"
      assert_equal 0, Transformation.filter(:id => transformation.id).count

      assert last_response.redirect?, "Wasn't redirected"
      assert_equal "http://example.org/projects/#{@project.id}/resources/#{@resource.id}", last_response['location']
    end

    test "delete with non existant transformation" do
      delete "/projects/#{@project.id}/resources/#{@resource.id}/transformations/8675309"
      assert last_response.redirect?
      assert_equal "http://example.org/projects/#{@project.id}/resources/#{@resource.id}/transformations", last_response['location']
      follow_redirect!
      assert_match /The transformation you were looking for doesn't exist/, last_response.body
    end

    test "for" do
      field = @resource.fields_dataset[:name => 'foo']
      t12n = Transformation.create!(:resource => @resource, :source_field => field, :transformer => @transformer)

      get "/projects/#{@project.id}/resources/#{@resource.id}/transformations/for/foo"
      assert_match /noop/, last_response.body
    end

    test "for with non existant field" do
      get "/projects/#{@project.id}/resources/#{@resource.id}/transformations/for/gobbledegook"
      assert last_response.ok?
      assert_equal '', last_response.body
    end

    test "index" do
      field = @resource.fields_dataset[:name => 'foo']
      t12n = Transformation.create!(:resource => @resource, :source_field => field, :transformer => @transformer)

      get "/projects/#{@project.id}/resources/#{@resource.id}/transformations"
      assert last_response.ok?
    end

    test "preview" do
      field = @resource.fields_dataset[:name => 'foo']
      params = {
        :transformer_id => @transformer.id.to_s,
        :source_field_id => field.id.to_s,
        :result_field_id => field.id.to_s
      }
      post "/projects/#{@project.id}/resources/#{@resource.id}/transformations/preview", :transformation => params
      assert last_response.ok?, last_response.body
    end
  end
end
