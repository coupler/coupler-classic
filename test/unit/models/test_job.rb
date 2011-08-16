require 'helper'

module CouplerUnitTests
  module ModelTests
    class TestJob < Coupler::Test::UnitTest
      def new_job(attribs = {})
        j = Job.new(attribs)
        if attribs[:resource]
          j.stubs(:resource_dataset).returns(stub({:all => [attribs[:resource]]}))
        end
        if attribs[:scenario]
          j.stubs(:scenario_dataset).returns(stub({:all => [attribs[:scenario]]}))
        end
        if attribs[:import]
          j.stubs(:import_dataset).returns(stub({:all => [attribs[:import]]}))
        end
        j
      end

      def setup
        super
        @project = stub('project', :pk => 1, :id => 1, :associations => {})
        @resource = stub('resource', :pk => 456, :id => 456, :associations => {})
        @scenario = stub('scenario', :pk => 456, :id => 456, :associations => {})
        @import = stub('import', :pk => 123, :id => 123, :associations => {}, :project_id => 1, :project => @project, :name => 'foo')
        @notification = stub('notification', :pk => 222, :id => 222, :associations => {})
        Coupler::Models::Notification.stubs(:create).returns(@notification)
      end

      test "sequel model" do
        assert_equal ::Sequel::Model, Job.superclass
        assert_equal :jobs, Job.table_name
      end

      test "belongs to resource" do
        assert_respond_to Job.new, :resource
      end

      test "belongs to scenario" do
        assert_respond_to Job.new, :scenario
      end

      test "belongs to import" do
        assert_respond_to Job.new, :import
      end

      test "belongs to notification" do
        assert_respond_to Job.new, :notification
      end

      test "percent completed" do
        job = new_job(:name => 'transform', :resource => @resource, :total => 200, :completed => 54)
        assert_equal 27, job.percent_completed
        job.total = 0
        assert_equal 0, job.percent_completed
      end

      test "execute transform" do
        job = new_job(:name => 'transform', :resource => @resource).save!

        now = Time.now
        @resource.expects(:source_dataset_count).returns(12345)
        seq = sequence("update")
        job.expects(:update).with(:status => 'running', :total => 12345, :started_at => now).in_sequence(seq)
        @resource.expects(:transform!).in_sequence(seq)
        job.expects(:status=).with('done').in_sequence(seq)
        job.expects(:completed_at=).with(now).in_sequence(seq)
        job.expects(:save).in_sequence(seq)
        Timecop.freeze(now) { job.execute }
      end

      test "failed transform sets failed status" do
        job = new_job(:name => 'transform', :resource => @resource).save!

        now = Time.now
        @resource.stubs(:source_dataset_count).returns(12345)
        seq = sequence("update")
        job.expects(:update).with(:status => 'running', :total => 12345, :started_at => now).in_sequence(seq)
        fake_exception_klass = Class.new(Exception)
        exception = fake_exception_klass.new("someone set us up the bomb")
        @resource.expects(:transform!).raises(exception).in_sequence(seq)
        job.expects(:update).with(has_entries(:status => 'failed', :completed_at => now, :error_msg => kind_of(String))).in_sequence(seq)

        Timecop.freeze(now) do
          begin
            job.execute
          rescue fake_exception_klass
          end
        end
      end

      test "execute run scenario" do
        job = new_job(:name => 'run_scenario', :scenario => @scenario).save!

        now = Time.now
        seq = sequence("update")
        job.expects(:update).with(:status => 'running', :started_at => now).in_sequence(seq)
        @scenario.expects(:run!).in_sequence(seq)
        job.expects(:status=).with('done').in_sequence(seq)
        job.expects(:completed_at=).with(now).in_sequence(seq)
        job.expects(:save).in_sequence(seq)

        Timecop.freeze(now) { job.execute }
      end

      test "failed run scenario sets failed status" do
        job = new_job(:name => 'run_scenario', :scenario => @scenario).save!

        now = Time.now
        seq = sequence("update")
        job.expects(:update).with(:status => 'running', :started_at => now).in_sequence(seq)
        fake_exception_klass = Class.new(Exception)
        exception = fake_exception_klass.new("someone set us up the bomb")
        @scenario.expects(:run!).raises(exception).in_sequence(seq)
        job.expects(:update).with(has_entries(:status => 'failed', :completed_at => now, :error_msg => kind_of(String))).in_sequence(seq)

        Timecop.freeze(now) do
          begin
            job.execute
          rescue fake_exception_klass
          end
        end
      end

      test "recently accessed" do
        now = Time.now
        job_1 = job_2 = job_3 = job_4 = nil
        Timecop.freeze(now - 3) { job_1 = new_job(:name => "run_scenario", :scenario => @scenario).save! }
        Timecop.freeze(now - 2) { job_2 = new_job(:name => "run_scenario", :scenario => @scenario).save! }
        Timecop.freeze(now - 1) { job_3 = new_job(:name => "run_scenario", :scenario => @scenario).save! }
        Timecop.freeze(now    ) { job_4 = new_job(:name => "run_scenario", :scenario => @scenario).save! }
        assert_equal [job_4, job_3, job_2], Job.recently_accessed
      end

      test "import job" do
        job = new_job(:name => 'import', :import => @import).save!

        now = Time.now
        seq = sequence("update")
        @import.expects(:data).returns(mock(:file => mock(:size => 12345)))
        job.expects(:update).with(:status => 'running', :total => 12345, :started_at => now).in_sequence(seq)
        @import.expects(:import!).returns(true).in_sequence(seq)
        @import.expects(:resource).returns(mock({:id => 456, :activate! => nil})).in_sequence(seq)
        Notification.expects(:create).with(:message => "Import finished successfully", :url => "/projects/1/resources/456").returns(@notification).in_sequence(seq)
        job.expects(:notification=).with(@notification).in_sequence(seq)
        job.expects(:status=).with('done').in_sequence(seq)
        job.expects(:completed_at=).with(now).in_sequence(seq)
        job.expects(:save).in_sequence(seq)
        Timecop.freeze(now) { job.execute }
      end

      test "import job with more interaction needed" do
        job = new_job(:name => 'import', :import => @import).save!

        now = Time.now
        seq = sequence("update")
        @import.expects(:data).returns(mock(:file => mock(:size => 12345)))
        job.expects(:update).with(:status => 'running', :total => 12345, :started_at => now).in_sequence(seq)
        @import.expects(:import!).returns(false).in_sequence(seq)
        Notification.expects(:create).with(:message => "Import finished, but with errors", :url => "/projects/1/imports/123/edit").returns(@notification)
        job.expects(:status=).with('done').in_sequence(seq)
        job.expects(:completed_at=).with(now).in_sequence(seq)
        job.expects(:save).in_sequence(seq)
        Timecop.freeze(now) { job.execute }
      end
    end
  end
end
