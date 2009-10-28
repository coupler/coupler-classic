require File.dirname(__FILE__) + "/../../test/helper"
require 'test/unit/assertions'
require 'celerity'

module CouplerWorld
  include Test::Unit::Assertions

  def app
    Coupler::Base.set :environment, :test
    Coupler::Base
  end
end

module CelerityHelpers
  def browser
    @browser ||= Celerity::Browser.new
  end

  def current_url
    browser.page.getWebResponse.getRequestUrl.toString
  end

  def current_page_source
    browser.page.as_xml
  end

  def visit(path)
    browser.goto("http://localhost:4567#{path}")
  end

  def fill_in(label_for_text_field, options = {})
    browser.text_field(:label, label_for_text_field).value = options[:with]
  end

  def select(option_text, options = {})
    browser.select_list(:label, options[:from]).select(option_text)
  end

  def click_button(button_value)
    browser.button(button_value).click
  end
end

Before do
  config = Coupler::Config.instance
  config.tables.each { |t| config[t].delete }
end

World(CouplerWorld, CelerityHelpers)
