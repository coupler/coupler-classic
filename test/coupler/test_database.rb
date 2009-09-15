require File.dirname(__FILE__) + '/../helper'

class TestDatabase < Test::Unit::TestCase
  def test_sequel_model
    assert_equal Sequel::Model, Coupler::Database.superclass
    assert_equal :databases, Coupler::Database.table_name
  end
end
