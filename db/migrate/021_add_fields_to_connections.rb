Sequel.migration do
  up do
    alter_table(:connections) do
      add_column :path, String
      add_column :database_name, String
    end
  end

  down do
    alter_table(:connections) do
      drop_column :path
      drop_column :database_name
    end
  end
end
