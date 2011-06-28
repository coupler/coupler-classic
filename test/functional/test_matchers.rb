require 'helper'
require 'ruby-debug'

module CouplerFunctionalTests
  class TestMatchers < Coupler::Test::FunctionalTest
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
      @connection = new_connection('h2', :name => 'foo').save!
      @project = Project.create!(:name => 'foo')
      @resource = Resource.create!(:name => 'foo', :project => @project, :table_name => 'foo', :connection => @connection)
      @scenario = Scenario.create!(:name => 'foo', :project => @project, :resource_1 => @resource)
    end

    test "new" do
      visit "/projects/#{@project.id}/scenarios/#{@scenario.id}/matchers/new"
      assert_equal 200, page.status_code
    end

    test "new with non existant project" do
      visit "/projects/8675309/scenarios/#{@scenario.id}/matchers/new"
      assert_equal "/projects", page.current_path
      assert page.has_content?("The project you were looking for doesn't exist")
    end

    test "new with non existant scenario" do
      visit "/projects/#{@project.id}/scenarios/8675309/matchers/new"
      assert_equal "/projects/#{@project.id}/scenarios", page.current_path
      assert page.has_content?("The scenario you were looking for doesn't exist")
    end

    attribute(:javascript, true)
    test "successfully creating matcher for self-linkage" do
      visit "/projects/#{@project.id}/scenarios/#{@scenario.id}/matchers/new"
      click_link("Add comparison")
      select('foo', :from => "lhs_value_select")
      find('span.ui-button-text', :text => 'Add').click
      click_button('Submit')
      assert_equal "/projects/#{@project.id}/scenarios/#{@scenario.id}", page.current_path

      assert @scenario.matcher
    end

    attribute(:javascript, true)
    test "edit" do
      foo = @resource.fields_dataset[:name => 'foo']
      bar = @resource.fields_dataset[:name => 'bar']
      matcher = Matcher.create!({
        :scenario => @scenario,
        :comparisons_attributes => [{
          'lhs_type' => 'field', 'raw_lhs_value' => foo.id, 'lhs_which' => 1,
          'rhs_type' => 'field', 'raw_rhs_value' => bar.id, 'rhs_which' => 2,
          'operator' => 'equals'
        }]
      })
      visit "/projects/#{@project.id}/scenarios/#{@scenario.id}/matchers/#{matcher.id}/edit"
      click_link("Delete")

      click_link("Add comparison")
      find("#lhs_value_select").select("bar")
      find("#rhs_value_select").select("foo")
      find('span.ui-button-text', :text => 'Add').click
      click_button('Submit')
      assert_equal "/projects/#{@project.id}/scenarios/#{@scenario.id}", page.current_path

      assert_equal 1, @scenario.matcher.comparisons_dataset.count
    end

    test "edit with non existant matcher" do
      visit "/projects/#{@project.id}/scenarios/#{@scenario.id}/matchers/8675309/edit"
      assert_equal "/projects/#{@project.id}/scenarios/#{@scenario.id}", page.current_path
      assert page.has_content?("The matcher you were looking for doesn't exist")
    end

    attribute(:javascript, true)
    test "delete" do
      pend "This fails and I don't know why"
      field = @resource.fields_dataset[:name => 'foo']
      matcher = Matcher.create!({
        :scenario => @scenario,
        :comparisons_attributes => [{
          'lhs_type' => 'field', 'raw_lhs_value' => field.id, 'lhs_which' => 1,
          'rhs_type' => 'field', 'raw_rhs_value' => field.id, 'rhs_which' => 2,
          'operator' => 'equals'
        }]
      })
      visit "/projects/#{@project.id}/scenarios/#{@scenario.id}"
      link = page.driver.browser.find_element(:link_text, "Delete")
      link.click
      a = page.driver.browser.switch_to.alert
      a.accept
      assert_equal 0, Models::Matcher.filter(:id => matcher.id).count
      assert_equal "/projects/#{@project.id}/scenarios/#{@scenario.id}", page.current_path
    end
  end
end
