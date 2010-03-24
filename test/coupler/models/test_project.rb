require File.dirname(__FILE__) + '/../../helper'

module Coupler
  module Models
    class TestProject < Test::Unit::TestCase
      def test_sequel_model
        assert_equal ::Sequel::Model, Project.superclass
        assert_equal :projects, Project.table_name
      end

      def test_one_to_many_resources
        assert_respond_to Project.new, :resources
      end

      def test_one_to_many_scenarios
        assert_respond_to Project.new, :scenarios
      end

      def test_requires_name
        project = ::Factory.build(:project, :name => nil)
        assert !project.valid?

        project.name = ""
        assert !project.valid?
      end

      def test_sets_slug_from_name
        project = Project.create('name' => 'Foo bar')
        assert_equal "foo_bar", project.slug
      end

      def test_requires_unique_slug
        project_1 = ::Factory.create(:project, :slug => 'pants')
        project_2 = ::Factory.build(:project, :name => 'foo', :slug => 'pants')
        assert !project_2.valid?

        project_2.slug = "roflslam"
        assert project_2.valid?
        project_2.save

        project_2.slug = "pants"
        assert !project_2.valid?
      end

      def test_saves_existing_project
        project = Factory(:project, :slug => 'pants')
        project.description = "Foo"
        assert project.valid?
        project.save
      end

      def test_timestamps_on_create
        Timecop.freeze(Time.now) do
          project = Factory(:project)
          assert_equal Time.now.to_i, project.created_at.to_i
          assert_equal Time.now.to_i, project.updated_at.to_i
        end
      end

      def test_timestamps_on_update
        project = Factory(:project)
        Timecop.freeze(1000) do
          project.description = "omg ponies"
          project.save!
          assert_equal Time.now.to_i, project.updated_at.to_i
        end
      end

      def test_versioning_new_record
        project = Factory(:project)
        assert_equal 1, project.version

        versions = Database.instance[:projects_versions].filter(:current_id => project.id)
        assert_equal 1, versions.count

        data = versions.first
        project.values.each_pair do |key, value|
          next  if key == :id
          assert_equal value, data[key], "#{key} didn't match"
        end
      end

      def test_versioning_existing_record
        project = Factory(:project)
        project.update(:name => "blah blah blah")
        assert_equal 2, project.version

        versions = Database.instance[:projects_versions].filter(:current_id => project.id, :version => 2)
        assert_equal 1, versions.count

        data = versions.first
        project.values.each_pair do |key, value|
          next  if key == :id
          if value.is_a?(Time)
            assert_equal value.to_i, data[key].to_i, "#{key} didn't match"
          else
            assert_equal value, data[key], "#{key} didn't match"
          end
        end
      end
    end
  end
end
