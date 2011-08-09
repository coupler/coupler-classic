module Coupler
  module Models
    class Job < Sequel::Model
      include CommonModel

      many_to_one :resource
      many_to_one :scenario
      many_to_one :import

      def percent_completed
        total > 0 ? completed * 100 / total : 0
      end

      def execute
        Logger.instance.info("Starting job #{id} (#{name})")

        opts = {}
        case name
        when 'transform'
          opts[:total] = resource.source_dataset_count
        when 'import'
          opts[:total] = import.data.file.size
        end

        begin
          opts[:status] = 'running'
          opts[:started_at] = Time.now
          update(opts)
          send("execute_#{name}")
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

      private

        def execute_transform
          resource.transform! { |n| update(:completed => completed + n) }
        end

        def execute_run_scenario
          scenario.run!
        end

        def execute_import
          last = Time.now # don't slam the database
          result = import.import! do |pos|
            now = Time.now
            if now - last >= 1
              last = now
              update(:completed => pos)
            end
          end
          if result
            resource = Resource.create(:import => import)
            Notification.create({
              :message => "Import finished successfully",
              :url => "/projects/#{import.project_id}/resources/#{resource.id}"
            })
          else
            Notification.create({
              :message => "Import finished, but with errors",
              :url => "/projects/#{import.project_id}/imports/#{import.id}/edit"
            })
          end
        end
    end
  end
end
