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

    test "flags notifications as seen when url is visited" do
      n = Notification.create(:message => "Foo bar", :url => "/connections")
      visit "/connections"
      n.reload
      assert n.seen
    end

    test "unseen json" do
      now = DateTime.now
      n1 = n2 = nil
      Timecop.freeze(now) do
        n1 = Notification.create(:message => "Foo bar", :url => "/connections")
        n2 = Notification.create(:message => "Seen foo bar", :url => "/projects", :seen => true)
      end
      page.driver.get "/notifications/unseen.json"
      result = JSON.parse(page.driver.response.body)
      assert_equal([{'id' => n1.id, 'message' => 'Foo bar', 'url' => '/connections', 'created_at' => now.to_s}], result)
    end
  end
end
