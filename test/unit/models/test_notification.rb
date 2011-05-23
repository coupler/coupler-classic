require 'helper'

module TestModels
  class TestNotification < Coupler::Test::UnitTest
    include Coupler::Models
    Coupler::Models::Notification  # force load

    test "sequel model" do
      assert_equal ::Sequel::Model, Notification.superclass
      assert_equal :notifications, Notification.table_name
    end

    test "common model" do
      assert Notification.ancestors.include?(CommonModel)
    end
  end
end
