require File.dirname(__FILE__) + '/../helper'

class TestResource < Test::Unit::TestCase
  def setup
    Coupler::Project.delete
    Coupler::Resource.delete
  end

  def test_sequel_model
    assert_equal Sequel::Model, Coupler::Resource.superclass
    assert_equal :resources, Coupler::Resource.table_name
  end

  def test_many_to_one_projects
    assert_respond_to Coupler::Resource.new, :project
  end

  def test_requires_name
    resource = Factory(:resource, :name => nil)
    assert !resource.valid?

    resource.name = ""
    assert !resource.valid?
  end

  def test_requires_unique_name_across_projects
    project = Factory(:project)
    resource_1 = Factory(:resource, :name => "avast", :project => project)
    resource_2 = Factory.build(:resource, :name => "avast", :project => project)
    assert !resource_2.valid?
  end
end
