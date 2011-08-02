Sequel.migration do
  up do
    add_column :jobs, :error_msg, String, :text => true
  end
end
