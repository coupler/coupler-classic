require 'helper'

module Coupler
  module Models
    class TestProject < Coupler::Test::UnitTest
      test "sequel model" do
        assert_equal ::Sequel::Model, Project.superclass
        assert_equal :projects, Project.table_name
      end

      test "one to many resources" do
        assert_respond_to Project.new, :resources
      end

      test "one to many scenarios" do
        assert_respond_to Project.new, :scenarios
      end

      test "requires name" do
        project = Project.new
        assert !project.valid?

        project.name = ""
        assert !project.valid?
      end

      test "requires unique name" do
        project_1 = Project.create(:name => "foo")
        project_2 = Project.new(:name => "foo")
        assert !project_2.valid?
      end

      test "sets slug from name" do
        project = Project.create('name' => 'Foo bar')
        assert_equal "foo_bar", project.slug
      end

      test "requires unique slug" do
        project_1 = Project.create(:name => "foo", :slug => 'foo')
        project_2 = Project.new(:name => 'bar', :slug => 'foo')
        assert !project_2.valid?

        project_2.slug = "bar"
        assert project_2.valid?
        project_2.save

        project_2.slug = "foo"
        assert !project_2.valid?
      end

      test "saves existing project" do
        project = Project.create(:name => "foo")
        project.description = "Foo"
        assert project.valid?
        project.save
      end

      test "local_database" do
        project = Project.create(:name => "foo")
        FileUtils.rm(Dir[Base.db_path("project_#{project.id}")+".*"])

        project.local_database do |db|
          assert_kind_of Sequel::JDBC::Database, db
          assert_match /project_#{project.id}/, db.uri
          assert db.test_connection
        end
      end

      test "deletes dependencies after destroy, but not versions" do
        project = Project.create(:name => "foo")
        project.expects(:resources_dataset).returns([mock(:delete_versions_on_destroy= => nil, :destroy => nil)])
        project.expects(:scenarios_dataset).returns([mock(:delete_versions_on_destroy= => nil, :destroy => nil)])
        project.destroy
      end

      test "deletes local database after destroy" do
        project = Project.create(:name => "foo")
        project.local_database { |db| db.test_connection }  # force creation of database
        project.destroy
        files = Dir[Base.db_path("project_#{project.id}")+".*"]
        assert files.empty?, files.inspect
      end

      test "deletes dependencies and versions after destroy" do
        project = Project.create(:name => "foo")
        project.delete_versions_on_destroy = true
        project.expects(:resources_dataset).returns([mock(:destroy => nil) { 
          expects(:delete_versions_on_destroy=).with(true)
        }])
        project.expects(:scenarios_dataset).returns([mock(:destroy => nil) { 
          expects(:delete_versions_on_destroy=).with(true)
        }])
        project.destroy
        assert_equal 0, Database.instance[:projects_versions].filter(:current_id => project.id).count
      end

      #def test_local_database_uses_connection_class
        #pend
      #end
    end
  end
end
