require 'helper'

module TestCoupler
  class TestConnection < Test::Unit::TestCase
    test "subclass of Sequel::Model" do
      assert_equal Sequel::Model, Coupler::Connection.superclass
    end
  end
end
