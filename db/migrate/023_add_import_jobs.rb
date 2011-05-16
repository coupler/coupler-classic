Sequel.migration do
  up do
    alter_table(:jobs) do
      add_column :import_id, Integer
    end
  end

  down do
    alter_table(:jobs) do
      drop_column :import_id
    end
  end
end
