Sequel.migration do
  up do
    add_column :jobs, :notification_id, Integer
  end
  down do
    drop_column :jobs, :notification_id
  end
end
