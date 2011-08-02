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

        opts = {}
        block = nil
        case name
        when 'transform'
          opts[:total] = resource.source_dataset_count
          block = lambda do
            resource.transform! { |n| update(:completed => completed + n) }
          end
        when 'run_scenario'
          block = lambda do
            scenario.run!
          end
        end

        begin
          opts[:status] = 'running'
          opts[:started_at] = Time.now
          update(opts)

          block.call
        rescue Exception => e
          message = "%s: %s\n  %s" % [e.class.to_s, e.to_s, e.backtrace.join("\n  ")]
          update({
            :status => 'failed',
            :completed_at => Time.now,
            :error_msg => message
          })
          Logger.instance.error("Job #{id} (#{name}) crashed: #{message}")
          raise e
        end
        update(:status => 'done', :completed_at => Time.now)
        Logger.instance.info("Job #{id} (#{name}) finished successfully")
      end
    end
  end
end
