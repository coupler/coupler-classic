require 'helper'

module CouplerUnitTests
  class TestLogger < Coupler::Test::UnitTest
    def test_delegation
      logger = Coupler::Logger.instance
      assert_kind_of ::Logger, logger.__getobj__
    end
  end
end
