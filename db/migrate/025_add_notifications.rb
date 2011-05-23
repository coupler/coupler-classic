Sequel.migration do
  up do
    create_table(:notifications) do
      primary_key :id
      String :message
      String :url
      TrueClass :seen
      Time :created_at
      Time :updated_at
    end
  end
  down do
    drop_table(:notifications)
  end
end
