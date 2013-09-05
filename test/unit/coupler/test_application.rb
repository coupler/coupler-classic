require 'helper'

module TestCoupler
  class TestApplication < Test::Unit::TestCase
    include Rack::Test::Methods
    include XhrHelper

    def app
      Coupler::Application
    end

    test "index" do
      get '/'
      assert last_response.ok?
      assert_match "sup?", last_response.body
    end
  end
end
