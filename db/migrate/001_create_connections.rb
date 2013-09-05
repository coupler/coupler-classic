Sequel.migration do
  up do
    create_table :connections do
      primary_key :id
      String :name
      String :adapter
      String :host
      Integer :port
      String :database
      String :user
      String :password
      DateTime :created_at
      DateTime :updated_at
    end
  end
end
