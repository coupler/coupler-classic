module Coupler
  module Models
    class Result < Sequel::Model
      include CommonModel
      many_to_one :scenario

      def snapshot
        origin_scenario = Scenario.as_of_version(scenario_id, scenario_version)
        time = origin_scenario[:updated_at]
        resource_1 = Resource.as_of_time(origin_scenario[:resource_1_id], time)
        resource_2 = Resource.as_of_time(origin_scenario[:resource_2_id], time)
        {
          :scenario => origin_scenario,
          :resource_1 => resource_1,
          :resource_2 => resource_2
        }
      end

      def to_csv
        csv = FasterCSV.new("")
        hash = snapshot
        if snapshot[:scenario][:linkage_type] == "self-linkage"
          rslug = snapshot[:resource_1][:slug]
          csv << %W{#{rslug}_id_1 #{rslug}_id_2 score}
        else
          rslug1 = snapshot[:resource_1][:slug]
          rslug2 = snapshot[:resource_2][:slug]
          csv << %W{#{rslug1}_id #{rslug2}_id score}
        end

        ScoreSet.find(score_set_id) do |score_set|
          score_set.all.each do |row|
            csv << row.values_at(:first_id, :second_id, :score)
          end
        end
        csv.close
        csv.string
      end

      private
        def before_save
          super
          self[:scenario_version] = scenario.version
        end
    end
  end
end