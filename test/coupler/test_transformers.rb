require File.dirname(__FILE__) + '/../helper'

class Coupler::TestTransformers < ActiveSupport::TestCase
  def test_registering
    before = Coupler::Transformers.list.keys
    klass = Class.new(Coupler::Transformers::Base)
    Coupler::Transformers.register(:foo, klass)
    assert_equal [:foo], Coupler::Transformers.list.keys - before
  end
end
