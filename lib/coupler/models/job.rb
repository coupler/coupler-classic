module Coupler
  module Models
    class Job < Sequel::Model
      include CommonModel

      many_to_one :resource
      many_to_one :scenario
      many_to_one :import
      many_to_one :notification

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
        self.status = 'done'
        self.completed_at = Time.now
        save
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
            # NOTE: This is a bug waiting to happen. Import doesn't verify
            # that it has a resource, but supposedly, it will always have
            # one. The resource gets created at the same time in the
            # controller.

            resource = import.resource
            resource.activate!
            self.notification = Notification.create({
              :message => "Import finished successfully",
              :url => "/projects/#{import.project_id}/resources/#{resource.id}"
            })
          else
            self.notification = Notification.create({
              :message => "Import finished, but with errors",
              :url => "/projects/#{import.project_id}/imports/#{import.id}/edit"
            })
          end
        end
    end
  end
end
