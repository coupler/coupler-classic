require 'helper'

module TestExtensions
  class TestMatchers < Coupler::Test::IntegrationTest
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
      get "/projects/#{@project.id}/scenarios/#{@scenario.id}/matchers/new"
      assert last_response.ok?
    end

    test "new with non existant project" do
      get "/projects/8675309/scenarios/#{@scenario.id}/matchers/new"
      assert last_response.redirect?
      assert_equal "http://example.org/projects", last_response['location']
      follow_redirect!
      assert_match /The project you were looking for doesn't exist/, last_response.body
    end

    test "new with non existant scenario" do
      get "/projects/#{@project.id}/scenarios/8675309/matchers/new"
      assert last_response.redirect?
      assert_equal "http://example.org/projects/#{@project.id}/scenarios", last_response['location']
      follow_redirect!
      assert_match /The scenario you were looking for doesn't exist/, last_response.body
    end

    test "successfully creating matcher" do
      field = @resource.fields_dataset[:name => 'foo']
      attribs = {
        'comparisons_attributes' => {
          '0' => {
            'lhs_type' => 'field', 'raw_lhs_value' => field.id.to_s,
            'rhs_type' => 'field', 'raw_rhs_value' => field.id.to_s,
            'operator' => 'equals'
          }
        }
      }
      post("/projects/#{@project.id}/scenarios/#{@scenario.id}/matchers", { 'matcher' => attribs })
      assert last_response.redirect?, "Wasn't redirected"
      assert_equal "http://example.org/projects/#{@project.id}/scenarios/#{@scenario.id}", last_response['location']

      assert @scenario.matcher
    end

    test "edit" do
      field = @resource.fields_dataset[:name => 'foo']
      matcher = Matcher.create!({
        :scenario => @scenario,
        :comparisons_attributes => [{
          'lhs_type' => 'field', 'raw_lhs_value' => field.id, 'lhs_which' => 1,
          'rhs_type' => 'field', 'raw_rhs_value' => field.id, 'rhs_which' => 2,
          'operator' => 'equals'
        }]
      })
      get "/projects/#{@project.id}/scenarios/#{@scenario.id}/matchers/#{matcher.id}/edit"
      assert last_response.ok?
    end

    test "edit with non existant matcher" do
      get "/projects/#{@project.id}/scenarios/#{@scenario.id}/matchers/8675309/edit"
      assert last_response.redirect?
      assert_equal "http://example.org/projects/#{@project.id}/scenarios/#{@scenario.id}", last_response['location']
      follow_redirect!
      assert_match /The matcher you were looking for doesn't exist/, last_response.body
    end

    test "updating matcher" do
      foo = @resource.fields_dataset[:name => 'foo']
      bar = @resource.fields_dataset[:name => 'foo']
      matcher = Matcher.create!({
        :scenario => @scenario,
        :comparisons_attributes => [{
          'lhs_type' => 'field', 'raw_lhs_value' => foo.id, 'lhs_which' => 1,
          'rhs_type' => 'field', 'raw_rhs_value' => bar.id, 'rhs_which' => 2,
          'operator' => 'equals'
        }]
      })
      comparison = matcher.comparisons.first

      attribs = {
        'comparisons_attributes' => {
          '0' => { 'id' => comparison.id, '_delete' => true },
          '1' => {
            'lhs_type' => 'field', 'raw_lhs_value' => bar.id.to_s,
            'rhs_type' => 'field', 'raw_rhs_value' => foo.id.to_s,
            'operator' => 'equals'
          }
        }
      }
      put "/projects/#{@project.id}/scenarios/#{@scenario.id}/matchers/#{matcher.id}", :matcher => attribs

      assert last_response.redirect?, "Wasn't redirected"
      assert_equal "http://example.org/projects/#{@project.id}/scenarios/#{@scenario.id}", last_response['location']
    end

    test "delete" do
      field = @resource.fields_dataset[:name => 'foo']
      matcher = Matcher.create!({
        :scenario => @scenario,
        :comparisons_attributes => [{
          'lhs_type' => 'field', 'raw_lhs_value' => field.id, 'lhs_which' => 1,
          'rhs_type' => 'field', 'raw_rhs_value' => field.id, 'rhs_which' => 2,
          'operator' => 'equals'
        }]
      })
      delete "/projects/#{@project.id}/scenarios/#{@scenario.id}/matchers/#{matcher.id}"
      assert_equal 0, Models::Matcher.filter(:id => matcher.id).count

      assert last_response.redirect?, "Wasn't redirected"
      assert_equal "http://example.org/projects/#{@project.id}/scenarios/#{@scenario.id}", last_response['location']
    end
  end
end
