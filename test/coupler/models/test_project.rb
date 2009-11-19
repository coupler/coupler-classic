require File.dirname(__FILE__) + '/../../helper'

module Coupler
  module Models
    class TestProject < ActiveSupport::TestCase
      def setup
        Project.delete
      end

      def test_sequel_model
        assert_equal ::Sequel::Model, Project.superclass
        assert_equal :projects, Project.table_name
      end

      def test_one_to_many_resources
        assert_respond_to Project.new, :resources
      end

      def test_requires_name
        project = ::Factory.build(:project, :name => nil)
        assert !project.valid?

        project.name = ""
        assert !project.valid?
      end

      def test_sets_slug_from_name
        project = Project.create('name' => 'Foo bar')
        assert_equal "foo-bar", project.slug
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
    end
  end
end
