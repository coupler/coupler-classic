require 'helper'

module TestExtensions
  class TestJobs < Coupler::Test::IntegrationTest
    def self.startup
      super
      conn = new_connection('h2', :name => 'foo')
      conn.database do |db|
        db.create_table!(:foo) do
          primary_key :id
          String :foo
        end
        db[:foo].insert({:foo => 'foo'})
        db[:foo].insert({:foo => 'bar'})
      end
    end

    def setup
      super
      @connection = new_connection('h2', :name => 'foo').save!
      @project = Project.create!(:name => 'foo')
      @resource = Resource.create!(:name => 'foo', :project => @project, :table_name => 'foo', :connection => @connection)
      @transformer = Transformer.create!(:name => 'foo', :code => 'value', :allowed_types => %w{string}, :result_type => 'string')
      @transformation = Transformation.create!({
        :resource => @resource, :transformer => @transformer,
        :source_field => @resource.fields_dataset[:name => 'foo']
      })
    end

    test "jobs" do
      job = Job.create!(:name => 'transform', :status => 'scheduled', :resource => @resource)
      get "/jobs"
      assert last_response.ok?
    end

    test "count" do
      scheduled_job = Job.create!(:name => 'transform', :status => 'scheduled', :resource => @resource)
      completed_job = Job.create!(:name => 'transform', :status => 'done', :resource => @resource, :completed_at => Time.now)
      get "/jobs/count"
      assert last_response.ok?
      assert_equal "1", last_response.body
    end

    test "progress" do
      job = Job.create!(:name => 'transform', :status => 'scheduled', :resource => @resource, :total => 200, :completed => 54)
      get "/jobs/#{job.id}/progress"
      assert last_response.ok?
      result = JSON.parse(last_response.body)
      assert_equal({'total' => 200, 'completed' => 54}, result)
    end
  end
end
