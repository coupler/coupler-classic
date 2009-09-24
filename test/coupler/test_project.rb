require File.dirname(__FILE__) + '/../helper'

class TestProject < Test::Unit::TestCase
  def test_sequel_model
    assert_equal Sequel::Model, Coupler::Project.superclass
    assert_equal :projects, Coupler::Project.table_name
  end
end
