require File.dirname(__FILE__) + '/../../helper'

class Coupler::Comparators::TestBase < Test::Unit::TestCase
  def setup
    super
    @comparator = Coupler::Comparators::Base.new({})
  end

  def test_score_raises_not_implemented_error
    assert_raises(NotImplementedError) do
      @comparator.score({}, {})
    end
  end
end
