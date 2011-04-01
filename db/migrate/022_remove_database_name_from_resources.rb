Sequel.migration do
  up do
    alter_table(:resources) { drop_column(:database_name) }
    alter_table(:resources_versions) { drop_column(:database_name) }
  end

  down do
    alter_table(:resources) { add_column(:database_name, String) }
    alter_table(:resources_versions) { add_column(:database_name, String) }
  end
end
