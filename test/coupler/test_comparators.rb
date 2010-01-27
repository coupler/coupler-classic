require File.dirname(__FILE__) + '/../helper'

class Coupler::TestComparators < Test::Unit::TestCase
  def test_registering
    before = Coupler::Comparators.list.keys
    klass = Class.new(Coupler::Comparators::Base)
    Coupler::Comparators.register("_foo_", klass)
    assert_equal ["_foo_"], Coupler::Comparators.list.keys - before
  end

  def test_finding
    klass = Class.new(Coupler::Comparators::Base)
    Coupler::Comparators.register("_bar_", klass)

    assert_equal klass, Coupler::Comparators["_bar_"]
  end
end
