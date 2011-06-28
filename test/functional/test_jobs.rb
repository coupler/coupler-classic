require 'helper'

module CouplerFunctionalTests
  class TestJobs < Coupler::Test::FunctionalTest
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

    attribute(:javascript, true)
    test "jobs" do
      visit "/projects/#{@project.id}/resources/#{@resource.id}"
      click_button "Transform now"
      a = page.driver.browser.switch_to.alert
      a.accept

      visit "/jobs"
      assert page.has_selector?("table.list tbody tr")
    end

    # Using Rack::Test directly here for JSON tests
    test "count" do
      scheduled_job = Job.create!(:name => 'transform', :status => 'scheduled', :resource => @resource)
      completed_job = Job.create!(:name => 'transform', :status => 'done', :resource => @resource, :completed_at => Time.now)
      page.driver.get "/jobs/count"
      assert_equal "1", page.driver.response.body
    end

    test "progress" do
      visit "/projects/#{@project.id}/resources/#{@resource.id}"
      click_button "Transform now"
      assert_equal "/projects/#{@project.id}/resources/#{@resource.id}", page.current_path

      job = @resource.scheduled_jobs.first
      job.update(:total => 200, :completed => 54)
      page.driver.get "/jobs/#{job.id}/progress"
      result = JSON.parse(page.driver.response.body)
      assert_equal({'total' => 200, 'completed' => 54}, result)
    end
  end
end
