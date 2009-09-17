require File.dirname(__FILE__) + '/../helper'

class TestResource < Test::Unit::TestCase
  def test_sequel_model
    assert_equal Sequel::Model, Coupler::Resource.superclass
    assert_equal :resources, Coupler::Resource.table_name
  end
end
