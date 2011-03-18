Sequel.migration do
  up do
    alter_table(:connections) do
      add_column :path, String
    end
  end

  down do
    alter_table(:connections) do
      drop_column :path
    end
  end
end
