Sequel.migration do
  up do
    alter_table(:imports) do
      add_column :field_names, String, :text => true
      add_column :primary_key_name, String
      add_column :has_headers, TrueClass
      add_column :has_duplicate_keys, TrueClass
      add_column :occurred_at, DateTime
      rename_column :fields, :field_types
    end
  end
  down do
    alter_table(:imports) do
      rename_column :field_types, :fields
      drop_column :field_names
      drop_column :primary_key_name
      drop_column :has_headers
      drop_column :has_duplicate_keys
      drop_column :occurred_at
    end
  end
end
