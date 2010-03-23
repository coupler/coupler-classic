require File.dirname(__FILE__) + '/../../helper'

module Coupler
  module Models
    class TestJob < Test::Unit::TestCase
      def test_sequel_model
        assert_equal ::Sequel::Model, Job.superclass
        assert_equal :jobs, Job.table_name
      end

      def test_belongs_to_resource
        assert_respond_to Job.new, :resource
      end

      def test_belongs_to_scenario
        assert_respond_to Job.new, :scenario
      end
    end
  end
end
