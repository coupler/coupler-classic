require 'helper'

module TestExtensions
  class TestResources < Coupler::Test::IntegrationTest
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

        db.create_table!(:bar) do
          primary_key :id
          String :baz
          String :quux
        end
      end
    end

    def setup
      super
      stamp = Time.now - 50
      @project = Project.create(:name => 'foo', :created_at => stamp)
      @connection = new_connection('h2', :name => 'h2 connection', :created_at => stamp).save!
    end

    test "index" do
      resource = Resource.create(:name => 'foo', :project => @project, :connection => @connection, :table_name => 'foo')
      get "/projects/#{@project.id}/resources"
      assert last_response.ok?
      assert @project.reload.last_accessed_at
    end

    test "index with non existant project" do
      get "/projects/8675309/resources"
      assert last_response.redirect?
      assert_equal "http://example.org/projects", last_response['location']
      follow_redirect!
      assert_match /The project you were looking for doesn't exist/, last_response.body
    end

    test "new resource" do
      get "/projects/#{@project.id}/resources/new"
      assert last_response.ok?

      doc = Nokogiri::HTML(last_response.body)
      assert_equal 1, doc.css("form[action='/projects/#{@project.id}/resources']").length
      %w{name table_name}.each do |name|
        assert_equal 1, doc.css("input[name='resource[#{name}]']").length
      end
    end

    test "successfully creating resource" do
      attribs = {
        'connection_id' => @connection.id.to_s,
        'name' => 'bar',
        'table_name' => 'bar'
      }
      post "/projects/#{@project.id}/resources", { 'resource' => attribs }
      resource = Resource[:name => 'bar', :project_id => @project.id]
      assert resource

      assert last_response.redirect?, "Wasn't redirected"
      assert_equal "http://example.org/projects/#{@project.id}/resources/#{resource.id}/edit", last_response['location']
    end

    test "failing to create resource" do
      attribs = {
        'connection_id' => @connection.id.to_s,
        'name' => '',
        'table_name' => 'bar'
      }
      post "/projects/#{@project.id}/resources", { 'resource' => attribs }
      assert last_response.ok?
      assert_match /Name is not present/, last_response.body
    end

    test "show resource" do
      resource = Resource.create!(:name => 'foo', :project => @project, :connection => @connection, :table_name => 'foo')
      field = resource.fields_dataset[:name => 'foo']
      transformer = Transformer.create!(:name => 'noop', :code => 'value', :allowed_types => %w{string}, :result_type => 'same')
      transformation = Transformation.create!(:resource => resource, :transformer => transformer, :source_field => field)

      get "/projects/#{@project[:id]}/resources/#{resource.id}"
      assert last_response.ok?

      doc = Nokogiri::HTML(last_response.body)
      tables = doc.css('table')

      # resource table
      rows = tables[0].css('tbody tr')
      assert_equal 3, rows.length
      rows.each_with_index do |row, i|
        cells = row.css('td')
        assert_equal %w{id foo bar}[i], cells[0].inner_html
      end
    end

    test "schedule transform job" do
      resource = Resource.create!(:name => 'foo', :project => @project, :connection => @connection, :table_name => 'foo')
      get "/projects/#{@project[:id]}/resources/#{resource[:id]}/transform"
      assert last_response.redirect?, "Wasn't redirected"
      assert_equal "http://example.org/projects/#{@project[:id]}/resources/#{resource[:id]}", last_response['location']
      assert Job.filter(:name => 'transform', :resource_id => resource.id, :status => 'scheduled').count == 1
    end

    #def test_progress
      #resource = Factory(:resource, :project => @project, :completed => 100, :total => 1000)
      #get "/projects/#{@project.id}/resources/#{resource.id}/progress"
      #assert last_response.ok?
      #assert_equal "10", last_response.body
    #end

    test "edit" do
      resource = Resource.create!(:name => 'foo', :project => @project, :connection => @connection, :table_name => 'foo')
      get "/projects/#{@project[:id]}/resources/#{resource.id}/edit"
      assert last_response.ok?
    end

    test "update" do
      resource = Resource.create!(:name => 'foo', :project => @project, :connection => @connection, :table_name => 'foo')
      field = resource.fields_dataset[:name => 'foo']
      put "/projects/#{@project[:id]}/resources/#{resource.id}", :resource => {
        :fields_attributes => [{'id' => field.id, 'is_selected' => 0}]
      }
      assert last_response.redirect?
    end

    test "update with no attributes" do
      resource = Resource.create!(:name => 'foo', :project => @project, :connection => @connection, :table_name => 'foo')
      put "/projects/#{@project[:id]}/resources/#{resource.id}"
      assert last_response.redirect?
    end

    #def test_delete
      #pend
    #end

    test "record" do
      resource = Resource.create!(:name => 'foo', :project => @project, :connection => @connection, :table_name => 'foo')
      get "/projects/#{@project.id}/resources/#{resource.id}/record/1"
      assert last_response.ok?
    end
  end
end
