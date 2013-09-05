require 'helper'

module TestCoupler
  class TestFile < Test::Unit::TestCase
    test "subclass of Sequel::Model" do
      assert_equal Sequel::Model, Coupler::File.superclass
    end
  end
end

