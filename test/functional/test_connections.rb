require 'helper'

module CouplerFunctionalTests
  class TestConnections < Coupler::Test::FunctionalTest
    def setup
      super
      @connections = []
      @configs = {}
      each_adapter do |adapter, config|
        conn = new_connection(adapter, :name => "#{adapter} connection").save!
        @connections << conn
        @configs[adapter] = config
      end
    end

    test "index" do
      visit "/connections"
      assert page.has_selector?('a[href="/connections/new"]')
    end

    test "new" do
      visit "/connections/new"
      assert page.has_selector?("form[action='/connections']")
      assert page.has_selector?("select[name='connection[adapter]']")
      %w{name host port username password}.each do |name|
        assert page.has_selector?("input[name='connection[#{name}]']")
      end
    end

    test "successfully creating connection" do
      attributes = @configs['mysql'].merge(:name => 'foo')

      visit "/connections/new"
      select 'MySQL', :from => "connection[adapter]"
      attributes.each_pair do |name, value|
        fill_in "connection[#{name}]", :with => value
      end
      click_button "Submit"

      connection = Connection[:name => 'foo']
      assert connection

      assert_equal "/connections", page.current_path
    end

    test "failing to create connection" do
      attributes = @configs['mysql'].merge(:name => nil)

      visit "/connections/new"
      select 'MySQL', :from => "connection[adapter]"
      attributes.each_pair do |name, value|
        fill_in "connection[#{name}]", :with => value
      end
      click_button "Submit"

      assert page.has_content?("Name is not present")
    end

    test "show" do
      @connections.each do |conn|
        visit "/connections/#{conn.id}"
        assert page.has_selector?("table.show")
      end
    end

    attribute(:javascript, true)
    test "destroy" do
      visit "/connections"
      find('span.ui-icon-trash').click
      a = page.driver.browser.switch_to.alert
      a.accept

      assert_equal '/connections', page.current_path
      assert_nil Models::Connection[@connections[0].id]
    end
  end
end
