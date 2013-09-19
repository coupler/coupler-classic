Sequel.migration do
  up do
    create_table :files do
      primary_key :id
      String :filename
      File :data
      String :format
      String :col_sep
      String :row_sep
      String :quote_char
      DateTime :created_at
      DateTime :updated_at
    end
  end
end
