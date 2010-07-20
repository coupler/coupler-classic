Sequel.migration do
  up do
    create_table :imports do
      primary_key :id
      String :name
      String :data
      String :type, :default => "csv"
      Text :fields
      Integer :project_id
      Time :created_at
      Time :updated_at
    end
    [:resources, :resources_versions].each do |name|
      alter_table(name) { add_column :import_id, Integer }
    end
  end

  down do
    [:resources, :resources_versions].each do |name|
      alter_table(name) { drop_column :import_id }
    end
    drop_table :imports
  end
end
