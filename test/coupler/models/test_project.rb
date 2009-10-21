require File.dirname(__FILE__) + '/../../helper'

module Coupler
  module Models
    class TestProject < Test::Unit::TestCase
      def setup
        Project.delete
      end

      def test_sequel_model
        assert_equal ::Sequel::Model, Project.superclass
        assert_equal :projects, Project.table_name
      end

      def test_sets_slug_from_name
        project = Project.create('name' => 'Foo bar')
        assert_equal "foo-bar", project.slug
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
        assert project.valid?
        project.save
      end
    end
  end
end
