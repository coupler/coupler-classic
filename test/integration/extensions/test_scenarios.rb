require 'helper'

module TestExtensions
  class TestScenarios < Coupler::Test::IntegrationTest
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
      get "/projects/#{@project.id}/scenarios"
      assert last_response.ok?
    end

    test "index of non existant project" do
      get "/projects/8675309/scenarios"
      assert last_response.redirect?
      assert_equal "http://example.org/projects", last_response['location']
      follow_redirect!
      assert_match /The project you were looking for doesn't exist/, last_response.body
    end

    test "show" do
      scenario = Scenario.create(:name => 'foo', :resource_1 => @resource, :project => @project)
      get "/projects/#{@project.id}/scenarios/#{scenario.id}"
      assert last_response.ok?
    end

    test "new" do
      get "/projects/#{@project.id}/scenarios/new"
      assert last_response.ok?
    end

    test "successfully creating scenario" do
      attribs = {
        'name' => 'foo',
        'resource_ids' => [@resource.id.to_s]
      }
      post "/projects/#{@project.id}/scenarios", { 'scenario' => attribs }
      scenario = Scenario[:name => 'foo', :project_id => @project.id]
      assert scenario
      assert_equal [@resource], scenario.resources

      assert last_response.redirect?, "Wasn't redirected"
      assert_equal "http://example.org/projects/#{@project.id}/scenarios/#{scenario.id}", last_response['location']
    end

    test "failing to create scenario" do
      post "/projects/#{@project.id}/scenarios", {
        'scenario' => { 'name' => nil, 'resource_ids' => [@resource.id.to_s] }
      }
      assert last_response.ok?
      assert_match /Name is not present/, last_response.body
    end

    test "run scenario" do
      scenario = Scenario.create(:name => 'foo', :resource_1 => @resource, :project => @project)
      get "/projects/#{@project.id}/scenarios/#{scenario.id}/run"
      assert last_response.redirect?, "Wasn't redirected"
      assert_equal "http://example.org/projects/#{@project[:id]}/scenarios/#{scenario[:id]}", last_response['location']
      assert Job.filter(:name => 'run_scenario', :scenario_id => scenario.id, :status => 'scheduled').count == 1
    end

    #def test_progress
      #scenario = Factory(:scenario, :project => @project, :completed => 100, :total => 1000)
      #get "/projects/#{@project.id}/scenarios/#{scenario.id}/progress"
      #assert last_response.ok?
      #assert_equal "10", last_response.body
    #end
  end
end
