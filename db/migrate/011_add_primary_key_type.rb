Sequel.migration do
  up do
    [:resources, :resources_versions].each do |name|
      alter_table(name) { add_column(:primary_key_type, String) }
      self[name].update(:primary_key_type => 'integer')
    end
  end

  down do
    alter_table(:resources) { drop_column(:primary_key_type) }
    alter_table(:resources_versions) { drop_column(:primary_key_type) }
  end
end
