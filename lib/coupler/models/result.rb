module Coupler
  module Models
    class Result < Sequel::Model
      include CommonModel
      many_to_one :scenario

      def snapshot
        origin_scenario = Scenario.as_of_version(scenario_id, scenario_version)
        time = origin_scenario.updated_at
        project = Project.as_of_time(origin_scenario.project_id, time)
        resource_1 = Resource.as_of_time(origin_scenario.resource_1_id, time)
        resource_2 = Resource.as_of_time(origin_scenario.resource_2_id, time)
        {
          :project => project,
          :scenario => origin_scenario,
          :resource_1 => resource_1,
          :resource_2 => resource_2
        }
      end

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

      def to_csv
        # grab primary keys and datasets from the scenario's resources
        rdatasets = []
        rkeys = []
        headers = []
        scenario.resources.each do |resource|
          field_names = resource.selected_fields_dataset.select(:name).order(:id).naked.map { |f| f[:name].to_sym }
          rdatasets << resource.final_dataset.select(*field_names)
          rkeys << resource.primary_key_sym
          headers |= field_names
        end
        headers << :coupler_group_id

        csv = FasterCSV.new("", :headers => true)
        csv << headers

        groups_records_dataset.each do |group_record|
          # 'which' is either 0 or 1 (or nil for self-linkages)
          # rdatasets can be either length 1 or 2
          which = group_record[:which] || 0
          rdataset = rdatasets[-which]
          rkey = rkeys[-which]

          record = rdataset[rkey => group_record[:record_id]]
          record[:coupler_group_id] = group_record[:group_id]
          csv << record   # slots everything correctly
        end

        rdatasets.each { |r| r.db.disconnect }
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
