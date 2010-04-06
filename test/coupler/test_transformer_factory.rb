require File.dirname(__FILE__) + "/../helper"

module Coupler
  class TestTransformerFactory < Test::Unit::TestCase
    def setup
      super
      @resource = Factory(:resource)
    end

    def test_build_returns_class
      klass = TransformerFactory.build(@resource) { value }
      assert_kind_of Class, klass
      assert_equal Transformers::Base, klass.superclass
    end

    def test_transform_noop
      klass = TransformerFactory.build(@resource) { value }
      transformer = klass.new(:field_name => "first_name")
      expected = {:id=>1, :first_name=>"Mister", :last_name=>"Dude"}
      assert_equal expected, transformer.transform({
        :id=>1, :first_name=>"Mister", :last_name=>"Dude"
      })
    end
  end
end
