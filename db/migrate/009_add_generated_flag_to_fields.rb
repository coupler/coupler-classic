Sequel.migration do
  up do
    [:fields, :fields_versions].each do |name|
      alter_table(name) { add_column(:is_generated, :boolean, :default => false) }
      self[name].update(:is_generated => false)
    end
  end

  down do
    alter_table(:fields) { drop_column(:is_generated) }
    alter_table(:fields_versions) { drop_column(:is_generated) }
  end
end
