require File.dirname(__FILE__) + '/../helper'

class TestBase < Test::Unit::TestCase
  def test_subclasses_sinatra_base
    assert_equal Sinatra::Base, Coupler::Base.superclass
  end

  def test_index
    get "/"
    assert last_response.ok?
  end
end
