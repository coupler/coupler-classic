Sequel.migration do
  up do
    create_table :imports do
      primary_key :id
      String :data
      String :type, :default => "csv"
      Text :fields
      Time :created_at
      Time :updated_at
    end
  end

  down do
    drop_table :imports
  end
end
