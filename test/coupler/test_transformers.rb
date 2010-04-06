require File.dirname(__FILE__) + '/../helper'

class Coupler::TestTransformers < Test::Unit::TestCase
  def test_registering
    before = Coupler::Transformers.list.keys
    klass = Class.new(Coupler::Transformers::Base)
    Coupler::Transformers.register("_foo_", klass)
    assert_equal ["_foo_"], Coupler::Transformers.list.keys - before
  end

  def test_finding
    klass = Class.new(Coupler::Transformers::Base)
    Coupler::Transformers.register("_bar_", klass)

    assert_equal klass, Coupler::Transformers["_bar_"]
  end

  def test_require_transformer
  end
end
