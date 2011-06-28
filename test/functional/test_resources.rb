require 'helper'

module CouplerFunctionalTests
  class TestResources < Coupler::Test::FunctionalTest
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
      visit "/projects/#{@project.id}/resources"
      assert_equal 200, page.status_code
      assert @project.reload.last_accessed_at
    end

    test "index with non existant project" do
      visit "/projects/8675309/resources"
      assert_equal "/projects", page.current_path
      assert page.has_content?("The project you were looking for doesn't exist")
    end

    attribute(:javascript, true)
    test "new database resource" do
      visit "/projects/#{@project.id}/resources/new"
      find('#resource-type-database').click
      fill_in("Name", :with => 'bar')
      fill_in("Table", :with => 'bar')
      select(@connection.name, :from => "Connection")
      click_button('Submit')
      assert_match %r{/projects/#{@project.id}/resources/\d+/edit}, page.current_path
      assert Resource[:name => 'bar', :project_id => @project.id]
    end

    attribute(:javascript, true)
    test "creating resource with errors" do
      visit "/projects/#{@project.id}/resources/new"
      find('#resource-type-database').click
      fill_in("Name", :with => '')
      fill_in("Table", :with => 'bar')
      select(@connection.name, :from => "Connection")
      click_button('Submit')
      assert_equal "/projects/#{@project.id}/resources", page.current_path
      assert page.has_content?("Name is not present")
    end

    test "show resource" do
      resource = Resource.create!(:name => 'foo', :project => @project, :connection => @connection, :table_name => 'foo')
      field = resource.fields_dataset[:name => 'foo']
      transformer = Transformer.create!(:name => 'noop', :code => 'value', :allowed_types => %w{string}, :result_type => 'same')
      transformation = Transformation.create!(:resource => resource, :transformer => transformer, :source_field => field)

      visit "/projects/#{@project[:id]}/resources/#{resource.id}"
      assert_equal 200, page.status_code

      rows = all('table#fields tbody tr')
      assert_equal 3, rows.length
      rows.each_with_index do |row, i|
        cells = row.all('td')
        assert_equal %w{id foo bar}[i], cells[0].text
      end
    end

    test "schedule transform job" do
      resource = Resource.create!(:name => 'foo', :project => @project, :connection => @connection, :table_name => 'foo')
      field = resource.fields_dataset[:name => 'foo']
      transformer = Transformer.create!(:name => 'noop', :code => 'value', :allowed_types => %w{string}, :result_type => 'same')
      transformation = Transformation.create!(:resource => resource, :transformer => transformer, :source_field => field)

      visit "/projects/#{@project[:id]}/resources/#{resource[:id]}"
      click_button("Transform now")
      assert_equal "/projects/#{@project[:id]}/resources/#{resource[:id]}", page.current_path
      assert Job.filter(:name => 'transform', :resource_id => resource.id, :status => 'scheduled').count == 1
    end

    #def test_progress
      #resource = Factory(:resource, :project => @project, :completed => 100, :total => 1000)
      #get "/projects/#{@project.id}/resources/#{resource.id}/progress"
      #assert last_response.ok?
      #assert_equal "10", last_response.body
    #end

    attribute(:javascript, true)
    test "edit" do
      resource = Resource.create!(:name => 'foo', :project => @project, :connection => @connection, :table_name => 'foo')
      field = resource.fields_dataset[:name => 'foo']

      visit "/projects/#{@project[:id]}/resources/#{resource.id}/edit"
      find("#field_checkbox_#{field.id}").click
      click_button('Submit')
      assert_equal "/projects/#{@project[:id]}/resources/#{resource.id}", page.current_path
    end

    #def test_delete
      #pend
    #end

    test "record" do
      resource = Resource.create!(:name => 'foo', :project => @project, :connection => @connection, :table_name => 'foo')
      page.driver.get "/projects/#{@project.id}/resources/#{resource.id}/record/1"
      assert_equal 200, page.status_code
    end
  end
end
