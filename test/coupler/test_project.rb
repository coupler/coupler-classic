require File.dirname(__FILE__) + '/../helper'

class Coupler::TestProject < Test::Unit::TestCase
  def setup
    Coupler::Project.delete
  end

  def test_sequel_model
    assert_equal Sequel::Model, Coupler::Project.superclass
    assert_equal :projects, Coupler::Project.table_name
  end

  def test_sets_slug_from_name
    project = Coupler::Project.create('name' => 'Foo bar')
    assert_equal "foo-bar", project.slug
  end

  def test_one_to_many_resources
    assert_respond_to Coupler::Project.new, :resources
  end

  def test_requires_name
    project = Factory.build(:project, :name => nil)
    assert !project.valid?

    project.name = ""
    assert !project.valid?
  end

  def test_requires_unique_slug
    project_1 = Factory(:project, :slug => 'pants')
    project_2 = Factory.build(:project, :name => 'foo', :slug => 'pants')
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
