require 'helper'

module TestExtensions
  class TestResults < Coupler::Test::IntegrationTest
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
      @project = Project.create!(:name => 'foo')
      @connection = new_connection('h2', :name => 'h2 connection').save!
      @resource = Resource.create!(:name => 'foo', :table_name => 'foo', :project => @project, :connection => @connection)
      @scenario = Scenario.create!(:name => 'foo', :resource_1 => @resource, :project => @project)
      foo = @resource.fields_dataset[:name => 'foo']
      bar = @resource.fields_dataset[:name => 'bar']
      @matcher = Matcher.create!({
        :scenario => @scenario,
        :comparisons_attributes => [{
          'lhs_type' => 'field', 'raw_lhs_value' => foo.id, 'lhs_which' => 1,
          'rhs_type' => 'field', 'raw_rhs_value' => bar.id, 'rhs_which' => 2,
          'operator' => 'equals'
        }]
      })
      @scenario.run!
      @result = @scenario.results_dataset.first
    end

    test "index" do
      get "/projects/#{@project.id}/scenarios/#{@scenario.id}/results"
      assert last_response.ok?
    end

    test "index with non existant project" do
      get "/projects/8675309/scenarios/#{@scenario.id}/results"
      assert last_response.redirect?
      assert_equal "http://example.org/projects", last_response['location']
      follow_redirect!
      assert_match /The project you were looking for doesn't exist/, last_response.body
    end

    test "index with non existant scenario" do
      get "/projects/#{@project.id}/scenarios/8675309/results"
      assert last_response.redirect?
      assert_equal "http://example.org/projects/#{@project.id}/scenarios", last_response['location']
      follow_redirect!
      assert_match /The scenario you were looking for doesn't exist/, last_response.body
    end

    test "show" do
      get "/projects/#{@project.id}/scenarios/#{@scenario.id}/results/#{@result.id}"
      assert last_response.ok?
    end

    test "details" do
      group_id = nil
      @result.groups_dataset { |ds| group_id = ds.get(:id) }
      get "/projects/#{@project.id}/scenarios/#{@scenario.id}/results/#{@result.id}/details/#{group_id}"
      assert last_response.ok?
    end

    test "show sends csv" do
      get "/projects/#{@project.id}/scenarios/#{@scenario.id}/results/#{@result.id}.csv"
      assert_equal %{attachment; filename="#{@scenario.slug}-run-#{@result.created_at.strftime('%Y%m%d-%H%M')}.csv"}, last_response['Content-Disposition']

      body = last_response.body
      regexp = /id,foo,bar,coupler_group_id/
      assert_match regexp, body
    end

    test "show with non existant result" do
      get "/projects/#{@project.id}/scenarios/#{@scenario.id}/results/8675309"
      assert last_response.redirect?
      assert_equal "http://example.org/projects/#{@project.id}/scenarios/#{@scenario.id}/results", last_response['location']
      follow_redirect!
      assert_match /The result you were looking for doesn't exist/, last_response.body
    end
  end
end
