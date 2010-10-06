module Coupler
  module Models
    class Scenario
      class GroupManager
        def initialize(parent)
          @num = 0
          @mutex = Mutex.new
          setup_groups_buffer
        end

        def next_group
          @mutex.synchronize { @num += 1 }
        end

        private
          def setup_groups_buffer
            columns = [
              {:name => :id, :type => Integer},
              {:name => :resource_id, :type => Integer},
              {:name => :matcher_id, :type => Integer},
            ]
            @parent.matchers.each do |matcher|
              matcher.comparisons.each do |comparison|
                if !comparison.blocking?
                  fields = comparison.fields
                  matcher_pairs << fields
                  groups_columns.push(fields[0].local_column_options.merge(:name => :"field_#{fields[0].id}"))
                  if fields[1] != fields[0]
                    groups_columns.push(fields[1].local_column_options.merge(:name => :"field_#{fields[1].id}"))
                  end
                end
              end
              pairs[matcher.id] = matcher_pairs
            end
            groups_name = :"groups_#{run_count}"
            db.create_table!(groups_name) do
              columns.push(*groups_columns)
            end
            groups_dataset = db[groups_name]
            groups_buffer = ImportBuffer.new(groups_columns.collect { |c| c[:name] }, groups_dataset)
          end
      end
    end
  end
end
