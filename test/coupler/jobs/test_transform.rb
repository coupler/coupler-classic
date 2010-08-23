require File.dirname(__FILE__) + '/../../helper'

module Coupler
  module Jobs
    class TestTransform < Test::Unit::TestCase
      def test_becomes_java
        assert_not_nil Transform.java_class
      end

      def test_implements_quartz_job
        assert Transform.java_class.interfaces.include?(org.quartz.Job.java_class)
      end

      def test_execute
        job_data_map = mock("job data map")
        job_data_map.expects(:get).with("resource_id").returns(1)
        job_data_map.expects(:get).with("job_id").returns(1)
        job_detail = stub("job detail", :job_data_map => job_data_map)
        context = stub("context", :job_detail => job_detail)

        job_ds = mock("job_ds") do
          expects(:update).with(:total => 12345)
        end
        Models::Job.expects(:filter).with(:id => 1).returns(job_ds)

        dataset = mock("dataset", :count => 12345)
        resource = mock("resource", :transform! => nil) do
          expects(:source_dataset).yields(dataset)
        end
        Models::Resource.expects(:[]).with(:id => 1).returns(resource)

        job = Transform.new
        job.execute(context)
      end
    end
  end
end
