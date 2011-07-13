require 'helper'

module CouplerUnitTests
  class TestBase < Coupler::Test::UnitTest
    def test_subclasses_sinatra_base
      assert_equal Sinatra::Base, Coupler::Base.superclass
    end
  end
end
