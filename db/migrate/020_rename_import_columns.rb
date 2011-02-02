Sequel.migration do
  up do
    alter_table(:imports) do
      rename_column :file_name, :data
    end
  end
  down do
    alter_table(:imports) do
      rename_column :data, :file_name
    end
  end
end
