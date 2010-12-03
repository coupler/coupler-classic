require File.dirname(__FILE__) + '/../../helper'

module Coupler
  module Extensions
    class TestResources < Test::Unit::TestCase
      def setup
        super
        Timecop.freeze(Time.now - 50) do
          @project = Factory(:project)
          @connection = Factory(:connection)
        end
      end

      def test_index
        resource = Factory(:resource, :project => @project)
        time = Time.now - 25
        Timecop.freeze(time) do
          get "/projects/#{@project.id}/resources"
        end
        assert last_response.ok?
        assert_equal time.to_i, @project.reload.last_accessed_at.to_i
      end

      def test_index_with_non_existant_project
        get "/projects/8675309/resources"
        assert last_response.redirect?
        assert_equal "http://example.org/projects", last_response['location']
        follow_redirect!
        assert_match /The project you were looking for doesn't exist/, last_response.body
      end

      def test_new_resource
        get "/projects/#{@project.id}/resources/new"
        assert last_response.ok?

        doc = Nokogiri::HTML(last_response.body)
        assert_equal 1, doc.css("form[action='/projects/#{@project.id}/resources']").length
        %w{name table_name}.each do |name|
          assert_equal 1, doc.css("input[name='resource[#{name}]']").length
        end
      end

      def test_successfully_creating_resource
        connection = Factory(:connection)
        attribs = Factory.attributes_for(:resource, :connection_id => connection.id)
        post "/projects/#{@project.id}/resources", { 'resource' => attribs }
        resource = Models::Resource[:name => attribs[:name], :project_id => @project.id]
        assert resource

        assert last_response.redirect?, "Wasn't redirected"
        follow_redirect!
        assert_equal "http://example.org/projects/#{@project.id}/resources/#{resource.id}/edit", last_request.url
      end

      def test_failing_to_create_resource
        connection = Factory(:connection)
        post "/projects/#{@project.id}/resources", {
          'resource' => Factory.attributes_for(:resource, :name => nil, :connection_id => connection.id)
        }
        assert last_response.ok?
        assert_match /Name is not present/, last_response.body
      end

      def test_show_resource
        resource = Factory(:resource, :project => @project)
        transformer = Factory(:transformer, :name => 'foo')
        transformation = Factory(:transformation, :transformer => transformer, :resource => resource)
        get "/projects/#{@project[:id]}/resources/#{resource.id}"
        assert last_response.ok?
        assert_match /#{resource.name.capitalize}/, last_response.body

        doc = Nokogiri::HTML(last_response.body)

        tables = doc.css('table')

        # resource table
        rows = tables[0].css('tbody tr')
        assert_equal 4, rows.length
        rows.each_with_index do |row, i|
          cells = row.css('td')
          assert_equal %w{id first_name last_name age}[i], cells[0].inner_html
        end
      end

      def test_transform_resource
        resource = stub("resource", :new? => false, :name => "foo", :slug => "foo", :id => 1)
        @scheduler = mock("scheduler") do
          expects(:schedule_transform_job).with(resource)
        end
        Scheduler.stubs(:instance).returns(@scheduler)
        Models::Project.stubs(:[]).returns(@project)
        @project.stubs(:resources_dataset).returns(stub("resources dataset", :[] => resource))
        get "/projects/#{@project.id}/resources/123/transform"
        assert last_response.redirect?, "Wasn't redirected"
      end

      #def test_progress
        #resource = Factory(:resource, :project => @project, :completed => 100, :total => 1000)
        #get "/projects/#{@project.id}/resources/#{resource.id}/progress"
        #assert last_response.ok?
        #assert_equal "10", last_response.body
      #end

      def test_edit
        resource = Factory(:resource, :project => @project)
        get "/projects/#{@project[:id]}/resources/#{resource.id}/edit"
        assert last_response.ok?
      end

      def test_update
        resource = Factory(:resource, :project => @project)
        field = resource.fields_dataset.order('id DESC').first
        put "/projects/#{@project[:id]}/resources/#{resource.id}", :resource => { 
          :fields_attributes => [{'id' => field.id, 'is_selected' => 0}]
        }
        assert last_response.redirect?
      end

      def test_update_with_no_attributes
        resource = Factory(:resource, :project => @project)
        put "/projects/#{@project[:id]}/resources/#{resource.id}"
        assert last_response.redirect?
      end

      def test_delete
        pend
      end

      def test_record
        resource = Factory(:resource, :project => @project)
        get "/projects/#{@project.id}/resources/#{resource.id}/record/1"
        assert last_response.ok?
      end
    end
  end
end
