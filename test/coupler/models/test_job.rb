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

      def test_percent_completed
        job = Factory(:resource_job, :total => 200, :completed => 54)
        assert_equal 27, job.percent_completed
        job.total = 0
        assert_equal 0, job.percent_completed
      end
    end
  end
end
