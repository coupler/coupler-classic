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

      def test_progress
        job = Factory(:resource_job, :total => 200, :completed => 54)
        get "/jobs/#{job.id}/progress"
        assert last_response.ok?
        result = JSON.parse(last_response.body)
        assert_equal({'total' => 200, 'completed' => 54}, result)
      end
    end
  end
end
