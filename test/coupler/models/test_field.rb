require File.dirname(__FILE__) + '/../../helper'

module Coupler
  module Models
    class TestField < Test::Unit::TestCase
      def test_sequel_model
        assert_equal ::Sequel::Model, Field.superclass
        assert_equal :fields, Field.table_name
      end

      def test_many_to_one_resource
        assert_respond_to Field.new, :resource
      end
    end
  end
end
