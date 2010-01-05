require File.dirname(__FILE__) + '/../../helper'

module Coupler
  module Extensions
    class TestResources < ActiveSupport::TestCase
      def setup
        @project = ::Factory.create(:project, :slug => "roflcopter")
        @database = mock("sequel database")
        @database.stubs(:test_connection).returns(true)
        @database.stubs(:tables).returns([:people])
        Models::Resource.any_instance.stubs(:connection).returns(@database)
        Models::Resource.any_instance.stubs(:schema).returns([[:id, {:allow_null=>false, :default=>nil, :primary_key=>true, :db_type=>"int(11)", :type=>:integer, :ruby_default=>nil}], [:first_name, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"varchar(50)", :type=>:string, :ruby_default=>nil}], [:last_name, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"varchar(50)", :type=>:string, :ruby_default=>nil}]])
      end

      def test_new_resource
        get "/projects/roflcopter/resources/new"
        assert last_response.ok?

        doc = Nokogiri::HTML(last_response.body)
        assert_equal 1, doc.css('form[action="/projects/roflcopter/resources"]').length
        assert_equal 1, doc.css("select[name='resource[adapter]']").length
        %w{name host port username password database_name table_name}.each do |name|
          assert_equal 1, doc.css("input[name='resource[#{name}]']").length
        end
      end

      def test_successfully_creating_resource
        attribs = Factory.attributes_for(:resource)
        post "/projects/roflcopter/resources", { 'resource' => attribs }
        resource = Models::Resource[:name => attribs[:name], :project_id => @project.id]
        assert resource

        assert last_response.redirect?, "Wasn't redirected"
        follow_redirect!
        assert_equal "http://example.org/projects/roflcopter/resources/#{resource.id}", last_request.url
      end

      def test_failing_to_create_resource
        post "/projects/roflcopter/resources", {
          'resource' => Factory.attributes_for(:resource, :name => nil)
        }
        assert last_response.ok?
        assert_match /Name is required/, last_response.body
      end

      def test_show_resource
        resource = Factory(:resource, :name => "roflsauce", :project => @project)
        transformation = Factory(:transformation, :transformer_name => 'downcaser', :resource => resource)
        get "/projects/roflcopter/resources/#{resource.id}"
        assert last_response.ok?

        doc = Nokogiri::HTML(last_response.body)
        assert_equal "roflsauce in #{@project.name}", doc.at('h1').inner_html

        tables = doc.css('table')

        # resource table
        rows = tables[0].css('tbody tr')
        assert_equal 3, rows.length
        rows.each_with_index do |row, i|
          cells = row.css('td')
          assert_equal %w{id first_name last_name}[i], cells[0].inner_html
        end

        # transformations table
        rows = tables[1].css('tbody tr')
        assert_equal 1, rows.length
        cells = rows[0].css('td')
        assert_equal %w{first_name downcaser}, cells.collect(&:inner_html)
      end

      def test_transform_resource
        resource = mock("resource")
        @scheduler = mock("scheduler") do
          expects(:schedule_transform_job).with(resource)
        end
        Scheduler.stubs(:instance).returns(@scheduler)
        Models::Project.stubs(:[]).returns(@project)
        @project.stubs(:resources_dataset).returns(stub("resources dataset", :[] => resource))
        get "/projects/roflcopter/resources/123/transform"
        assert last_response.ok?
      end
    end
  end
end
