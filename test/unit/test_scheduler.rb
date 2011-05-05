require 'helper'

module Coupler
  class TestScheduler < Coupler::Test::UnitTest
    test "schedule transform job" do
      resource = mock('resource')
      Models::Job.expects(:create).with({
        :name => "transform",
        :resource => resource,
        :status => "scheduled"
      })

      Scheduler.instance.schedule_transform_job(resource)
    end

    test "schedule run scenario job" do
      scenario = mock('scenario')
      Models::Job.expects(:create).with({
        :name => "run_scenario",
        :scenario => scenario,
        :status => "scheduled"
      })

      Scheduler.instance.schedule_run_scenario_job(scenario)
    end

    test "run_jobs executes first scheduled job" do
      running_dataset = mock('dataset')
      scheduled_dataset = mock('dataset')
      job = mock('job')

      seq = sequence('query')
      Models::Job.expects(:filter).with(:status => 'running').returns(running_dataset).in_sequence(seq)
      running_dataset.expects(:count).returns(0).in_sequence(seq)
      Models::Job.expects(:filter).with(:status => 'scheduled').returns(scheduled_dataset).in_sequence(seq)
      scheduled_dataset.expects(:order).with(:created_at).returns(scheduled_dataset).in_sequence(seq)
      scheduled_dataset.expects(:first).returns(job).in_sequence(seq)
      Thread.expects(:new).with(job).yields(job).in_sequence(seq)
      job.expects(:execute).in_sequence(seq)
      Scheduler.instance.run_jobs
    end

    test "run_jobs does not execute job if one already running" do
      running_dataset = mock('dataset')

      Models::Job.expects(:filter).with(:status => 'running').returns(running_dataset)
      running_dataset.expects(:count).returns(1)
      Models::Job.expects(:filter).with(:status => 'scheduled').never
      Scheduler.instance.run_jobs
    end

    test "start and shutdown" do
      scheduler = Scheduler.instance
      thread = stub('thread')
      Thread.expects(:new).once.returns(thread)
      scheduler.start
      assert scheduler.is_started?

      scheduler.start # don't start again

      thread.expects(:exit).once
      scheduler.shutdown
      assert !scheduler.is_started?
    end
  end
end
