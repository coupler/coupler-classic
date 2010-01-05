require File.dirname(__FILE__) + '/../../helper'

class Coupler::Comparators::TestBase < ActiveSupport::TestCase
  def setup
    @comparator = Coupler::Comparators::Base.new
  end

  def test_score_raises_not_implemented_error
    assert_raises(NotImplementedError) do
      @comparator.score
    end
  end
end
