Sequel.migration do
  up do
    create_table :files do
      primary_key :id
      String :filename
      File :data
      DateTime :created_at
      DateTime :updated_at
    end
  end
end
