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
        case name
        when 'transform'
          update(:status => 'running', :total => resource.source_dataset_count)
          begin
            resource.transform! { |n| update(:completed => completed + n) }
            update(:status => 'done')
          rescue Exception => e # FIXME: probably should handle each exception explicitly :)
            update(:status => 'failed')
          end
        when 'run_scenario'
          update(:status => 'running')
          begin
            scenario.run!
            update(:status => 'done')
          rescue Exception => e # FIXME: again
            update(:status => 'failed')
          end
        end
      end
    end
  end
end
