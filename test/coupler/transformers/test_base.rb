require File.dirname(__FILE__) + '/../../helper'

class Coupler::Transformers::TestBase < ActiveSupport::TestCase
  def setup
    @transformer = Coupler::Transformers::Base.new({})
  end

  def test_transform_raises_not_implemented_error
    assert_raises(NotImplementedError) do
      @transformer.transform({})
    end
  end

  def test_schema_returns_schema_unchanged
    assert_equal ['foo', 'bar'], @transformer.schema(['foo', 'bar'])
  end
end
