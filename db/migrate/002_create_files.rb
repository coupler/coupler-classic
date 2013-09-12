Sequel.migration do
  up do
    create_table :files do
      primary_key :id
      String :filename
      File :data
      String :format
      String :col_sep, :default => ','
      String :row_sep, :default => 'auto'
      String :quote_char, :default => '"'
      DateTime :created_at
      DateTime :updated_at
    end
  end
end
