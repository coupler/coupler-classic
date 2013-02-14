require 'helper'

module CouplerFunctionalTests
  class TestTransformations < Coupler::Test::FunctionalTest
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

    attribute(:javascript, true)
    test "new" do
      pend "I hate Capybara sometimes"
      visit "/projects/#{@project.id}/resources/#{@resource.id}/transformations/new"
      find('#source-field-name input.ui-autocomplete-input').set('foo')
      find('#transformer-name input.ui-autocomplete-input').set(@transformer.name)
      choose("Same as source field")
      click_button('Submit')
      assert_equal "/projects/#{@project.id}/resources/#{@resource.id}", page.current_path
      transformation = @resource.transformations_dataset.first
      assert transformation
    end

    test "new with non existant project" do
      visit "/projects/8675309/resources/#{@resource.id}/transformations/new"
      assert_equal "/projects", page.current_path
      assert page.has_content?("The project you were looking for doesn't exist")
    end

    attribute(:javascript, true)
    test "new with non existant resource" do
      visit "/projects/#{@project.id}/resources/8675309/transformations/new"
      assert_equal "/projects/#{@project.id}/resources", page.current_path
      assert page.has_content?("The resource you were looking for doesn't exist")
    end

    attribute(:javascript, true)
    test "delete" do
      field = @resource.fields_dataset[:name => 'foo']
      transformation = Transformation.create!(:resource => @resource, :transformer => @transformer, :source_field => field)

      visit "/projects/#{@project.id}/resources/#{@resource.id}/transformations"
      find('span.ui-icon-trash').click
      a = page.driver.browser.switch_to.alert
      a.accept
      assert_equal "/projects/#{@project.id}/resources/#{@resource.id}", page.current_path
      assert_equal 0, Transformation.filter(:id => transformation.id).count
    end

    # NOTE: Capybara doesn't do so well with this
    #test "delete with non existant transformation" do
      #page.driver.delete "/projects/#{@project.id}/resources/#{@resource.id}/transformations/8675309"
      #assert_equal "/projects/#{@project.id}/resources/#{@resource.id}/transformations", page.current_path
      #assert page.has_content?("The transformation you were looking for doesn't exist")
    #end

    test "for" do
      field = @resource.fields_dataset[:name => 'foo']
      t12n = Transformation.create!(:resource => @resource, :source_field => field, :transformer => @transformer)

      page.driver.get "/projects/#{@project.id}/resources/#{@resource.id}/transformations/for/foo"
      assert page.has_content?("noop")
    end

    # NOTE: Capybara doesn't do so well with this
    #test "for with non existant field" do
      #page.driver.get "/projects/#{@project.id}/resources/#{@resource.id}/transformations/for/gobbledegook"
      #assert_equal 200, page.status_code
      #assert_equal '', page.html
    #end

    test "index" do
      field = @resource.fields_dataset[:name => 'foo']
      t12n = Transformation.create!(:resource => @resource, :source_field => field, :transformer => @transformer)

      visit "/projects/#{@project.id}/resources/#{@resource.id}/transformations"
      assert_equal 200, page.status_code
    end

    test "preview" do
      field = @resource.fields_dataset[:name => 'foo']
      params = {
        :transformer_id => @transformer.id.to_s,
        :source_field_id => field.id.to_s,
        :result_field_id => field.id.to_s
      }
      page.driver.post "/projects/#{@project.id}/resources/#{@resource.id}/transformations/preview", :transformation => params
      assert_equal 200, page.status_code
    end
  end
end
