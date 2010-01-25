require File.dirname(__FILE__) + "/../helper"

module Coupler
  class TestLogger < ActiveSupport::TestCase
    def test_delegation
      logger = Coupler::Logger.instance
      assert_kind_of ::Logger, logger.__getobj__
    end
  end
end
