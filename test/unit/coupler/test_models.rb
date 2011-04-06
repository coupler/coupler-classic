require 'helper'

module Coupler
  class TestModels < Test::Unit::TestCase
    def test_lazy_loading_accepts_strings
      assert_nothing_raised do
        # This happens because Forgery calls const_missing directly with a string
        Models.const_missing("Resource")
      end
    end
  end
end
