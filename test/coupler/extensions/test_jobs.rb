require File.dirname(__FILE__) + '/../../helper'

module Coupler
  module Extensions
    class TestJobs < Test::Unit::TestCase
      def test_jobs
        job_1 = Factory(:resource_job)
        job_2 = Factory(:scenario_job)
        get "/jobs"
        assert last_response.ok?
      end

      def test_count
        scheduled_job = Factory(:resource_job)
        completed_job = Factory(:resource_job, :completed_at => Time.now)
        get "/jobs/count"
        assert last_response.ok?
        assert_equal "1", last_response.body
      end
    end
  end
end
