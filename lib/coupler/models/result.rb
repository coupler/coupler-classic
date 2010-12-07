module Coupler
  module Models
    class Result < Sequel::Model
      include CommonModel
      many_to_one :scenario

      def snapshot
        origin_scenario = Scenario.as_of_version(scenario_id, scenario_version)
        time = origin_scenario[:updated_at]
        project = Project.as_of_time(origin_scenario[:project_id], time)
        resource_1 = Resource.as_of_time(origin_scenario[:resource_1_id], time)
        resource_2 = Resource.as_of_time(origin_scenario[:resource_2_id], time)
        {
          :project => project,
          :scenario => origin_scenario,
          :resource_1 => resource_1,
          :resource_2 => resource_2
        }
      end

=begin
      def to_csv
        csv = FasterCSV.new("")
        hash = snapshot
        if snapshot[:scenario][:linkage_type] == "self-linkage"
          rslug = snapshot[:resource_1][:slug]
          csv << %W{#{rslug}_id_1 #{rslug}_id_2 score matcher_ids}
        else
          rslug1 = snapshot[:resource_1][:slug]
          rslug2 = snapshot[:resource_2][:slug]
          csv << %W{#{rslug1}_id #{rslug2}_id score matcher_ids}
        end

        ScoreSet.find(score_set_id) do |score_set|
          ds = score_set.select{[
            first_id,
            second_id,
            sum(score).cast(Integer).as(score),
            group_concat(matcher_id).as(matcher_ids)
          ]}.group(:first_id, :second_id)
          ds.each { |row| csv << row.values_at(:first_id, :second_id, :score, :matcher_ids) }
        end
        csv.close
        csv.string
      end
=end

      def groups_table_name
        :"groups_#{run_number}"
      end

      def groups_dataset
        if block_given?
          scenario.local_database do |db|
            yield db[groups_table_name]
          end
          nil
        else
          db = scenario.local_database
          db[groups_table_name]
        end
      end

      def groups_records_table_name
        :"groups_records_#{run_number}"
      end

      def groups_records_dataset
        if block_given?
          scenario.local_database do |db|
            yield db[groups_records_table_name]
          end
          nil
        else
          db = scenario.local_database
          db[groups_records_table_name]
        end
      end

      # This isn't really being used.
      def summary
        summary = {}
        summary[:fields] = scenario.matcher.comparisons.inject([]) do |arr, comparison|
          if !comparison.blocking?
            arr << comparison.fields.collect(&:name)
          end
          arr
        end
        scenario.local_database do |db|
          records_ds = db[:"groups_records_#{run_number}"]
          summary[:groups] = db[:"groups_#{run_number}"].collect do |group_row|
            group_row[:matches] = {}
            records_ds.select(:record_id, :which).filter(:group_id => group_row[:id]).each do |record_row|
              arr = group_row[:matches][record_row[:which]] ||= []
              arr.push(record_row[:record_id])
            end
            group_row
          end
          summary[:total_matches] = records_ds.group_and_count(:which).all
        end
        summary
      end

      private
        def before_save
          super
          self[:scenario_version] = scenario.version
        end
    end
  end
end
