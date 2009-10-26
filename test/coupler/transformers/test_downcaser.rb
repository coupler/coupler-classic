require File.dirname(__FILE__) + '/../../helper'

module Coupler
  module Transformers
    class TestDowncaser < ActiveSupport::TestCase
      def test_base_superclass
        assert_equal Coupler::Transformers::Base, Coupler::Transformers::Downcaser.superclass
      end

      def test_registers_itself
        assert Coupler::Transformers.list.include?(:downcaser)
      end

      def test_transform
        transformer = Downcaser.new(:field_name => 'first_name')
        expected = {:id=>1, :first_name=>"mister", :last_name=>"Dude"}
        assert_equal expected, transformer.transform({
          :id=>1, :first_name=>"Mister", :last_name=>"Dude"
        })
      end
    end
  end
end
