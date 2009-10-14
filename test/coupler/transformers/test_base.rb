require File.dirname(__FILE__) + '/../../helper'

class Coupler::Transformers::TestBase < Test::Unit::TestCase
  def test_transform_raises_not_implemented_error
    assert_raises(NotImplementedError) do
      Coupler::Transformers::Base.new.transform({})
    end
  end
end
