require 'helper'

module CouplerUnitTests
  class TestBase < Coupler::Test::UnitTest
    test "subclasses sinatra base" do
      assert_equal Sinatra::Base, Coupler::Base.superclass
    end
  end
end
