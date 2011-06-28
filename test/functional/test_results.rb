require 'helper'

module CouplerFunctionalTests
  class TestResults < Coupler::Test::FunctionalTest
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
      visit "/projects/#{@project.id}/scenarios/#{@scenario.id}/results"
      assert_equal 200, page.status_code
    end

    test "index with non existant project" do
      visit "/projects/8675309/scenarios/#{@scenario.id}/results"
      assert_equal "/projects", page.current_path
      assert page.has_content?("The project you were looking for doesn't exist")
    end

    test "index with non existant scenario" do
      visit "/projects/#{@project.id}/scenarios/8675309/results"
      assert_equal "/projects/#{@project.id}/scenarios", page.current_path
      assert page.has_content?("The scenario you were looking for doesn't exist")
    end

    test "show" do
      visit "/projects/#{@project.id}/scenarios/#{@scenario.id}/results/#{@result.id}"
      assert_equal 200, page.status_code
    end

    test "details" do
      group_id = nil
      @result.groups_dataset { |ds| group_id = ds.get(:id) }
      visit "/projects/#{@project.id}/scenarios/#{@scenario.id}/results/#{@result.id}/details/#{group_id}"
      assert_equal 200, page.status_code
    end

    test "show sends csv" do
      visit "/projects/#{@project.id}/scenarios/#{@scenario.id}/results/#{@result.id}.csv"
      assert_equal %{attachment; filename="#{@scenario.slug}-run-#{@result.created_at.strftime('%Y%m%d-%H%M')}.csv"}, page.response_headers['Content-Disposition']
      assert page.has_content?("id,foo,bar,coupler_group_id")
    end

    test "show with non existant result" do
      visit "/projects/#{@project.id}/scenarios/#{@scenario.id}/results/8675309"
      assert_equal "/projects/#{@project.id}/scenarios/#{@scenario.id}/results", page.current_path
      assert page.has_content?("The result you were looking for doesn't exist")
    end
  end
end
