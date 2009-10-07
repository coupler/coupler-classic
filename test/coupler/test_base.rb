require File.dirname(__FILE__) + '/../helper'

class Coupler::TestBase < Test::Unit::TestCase
  def test_subclasses_sinatra_base
    assert_equal Sinatra::Base, Coupler::Base.superclass
  end

  def test_index_when_no_projects
    get "/"
    assert last_response.ok?
    assert_match /Getting Started/, last_response.body
  end
end
