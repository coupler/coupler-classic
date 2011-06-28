require 'helper'

module CouplerFunctionalTests
  class TestScenarios < Coupler::Test::FunctionalTest
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
    end

    test "index" do
      scenario = Scenario.create(:name => 'foo', :resource_1 => @resource, :project => @project)
      visit "/projects/#{@project.id}/scenarios"
      assert_equal 200, page.status_code
    end

    test "index of non existant project" do
      visit "/projects/8675309/scenarios"
      assert_equal "/projects", page.current_path
      assert page.has_content?("The project you were looking for doesn't exist")
    end

    test "show" do
      scenario = Scenario.create(:name => 'foo', :resource_1 => @resource, :project => @project)
      visit "/projects/#{@project.id}/scenarios/#{scenario.id}"
      assert_equal 200, page.status_code
    end

    attribute(:javascript, true)
    test "successfully creating scenario" do
      visit "/projects/#{@project.id}/scenarios/new"
      fill_in('Name', :with => 'foo')
      fill_in('Description', :with => 'foo bar')
      find("#resource-#{@resource.id}").click
      click_button('Submit')
      assert_match %r{/projects/#{@project.id}/scenarios/\d+}, page.current_path
      scenario = Scenario[:name => 'foo', :project_id => @project.id]
      assert scenario
      assert_equal [@resource], scenario.resources
    end

    attribute(:javascript, true)
    test "failing to create scenario" do
      visit "/projects/#{@project.id}/scenarios/new"
      fill_in('Name', :with => '')
      fill_in('Description', :with => 'foo bar')
      find("#resource-#{@resource.id}").click
      click_button('Submit')
      assert_equal "/projects/#{@project.id}/scenarios", page.current_path
      assert page.has_content?("Name is not present")
    end

    test "run scenario" do
      scenario = Scenario.create(:name => 'foo', :resource_1 => @resource, :project => @project)
      foo = @resource.fields_dataset[:name => 'foo']
      matcher = Matcher.create!({
        :scenario => scenario,
        :comparisons_attributes => [{
          'lhs_type' => 'field', 'raw_lhs_value' => foo.id, 'lhs_which' => 1,
          'rhs_type' => 'field', 'raw_rhs_value' => foo.id, 'rhs_which' => 2,
          'operator' => 'equals'
        }]
      })
      visit "/projects/#{@project.id}/scenarios/#{scenario.id}"
      click_button('Run now')
      assert_equal "/projects/#{@project[:id]}/scenarios/#{scenario[:id]}", page.current_path
      assert Job.filter(:name => 'run_scenario', :scenario_id => scenario.id, :status => 'scheduled').count == 1
    end

    #def test_progress
      #scenario = Factory(:scenario, :project => @project, :completed => 100, :total => 1000)
      #visit "/projects/#{@project.id}/scenarios/#{scenario.id}/progress"
      #assert_equal 200, page.status_code
      #assert_equal "10", last_response.body
    #end
  end
end
