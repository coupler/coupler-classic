pp caller
module Coupler
  module Models
    class Job < Sequel::Model
      include CommonModel

      many_to_one :resource
      many_to_one :scenario

      def percent_completed
        total > 0 ? completed * 100 / total : 0
      end

      def execute
        Logger.instance.info("Starting job #{id} (#{name})")
        case name
        when 'transform'
          update(:status => 'running', :started_at => Time.now, :total => resource.source_dataset_count)

          new_status = 'failed'
          begin
            resource.transform! { |n| update(:completed => completed + n) }
            new_status = 'done'
          ensure
            update(:status => new_status, :completed_at => Time.now)
          end

        when 'run_scenario'
          update(:status => 'running', :started_at => Time.now)

          new_status = 'failed'
          begin
            scenario.run!
            new_status = 'done'
          ensure
            update(:status => new_status, :completed_at => Time.now)
          end
        end
        Logger.instance.info("Job #{id} (#{name}) finished")
      end
    end
  end
end
