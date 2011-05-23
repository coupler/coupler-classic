require 'helper'

module CouplerFunctionalTests
  class TestNotifications < Coupler::Test::FunctionalTest

    test "empty index" do
      visit "/notifications"
      assert_equal 200, page.status_code
    end

    test "index" do
      n1 = Notification.create(:message => "Test!")
      n2 = Notification.create(:message => "Another Test!", :url => "/projects")
      n3 = Notification.create(:message => "Foo", :seen => true)
      n4 = Notification.create(:message => "Bar", :url => "/connections", :seen => true)
      visit "/notifications"
      assert_equal 200, page.status_code
    end
  end
end
