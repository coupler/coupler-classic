require 'helper'

class TestCoupler < Test::Unit::TestCase
  def test_subclasses_sinatra_base
    assert_equal Sinatra::Base, Coupler.superclass
  end

  def test_adding_resource
    get "/resources/new"
    assert last_response.ok?

    doc = Nokogiri::HTML(last_response.body)
    assert_equal 1, doc.css('form[action="/resources/create"]').length
    assert_equal 1, doc.css('select[name=adapter]').length
  end
end
