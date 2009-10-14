require File.dirname(__FILE__) + '/../../helper'

class Coupler::Transformers::TestDowncase < Test::Unit::TestCase
  def test_base_superclass
    assert_equal Coupler::Transformers::Base, Coupler::Transformers::Downcase.superclass
  end

  def test_transform
  end

  def test_registers_itself
  end
end
