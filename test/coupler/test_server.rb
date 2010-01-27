require File.dirname(__FILE__) + "/../helper"
require File.join(File.dirname(__FILE__), '..', '..', 'lib', 'coupler', 'server')

module Coupler
  class TestServer < Test::Unit::TestCase
    def setup
      super
      @server = Server.instance
    end

    def test_truth
      assert true
    end
  end
end
