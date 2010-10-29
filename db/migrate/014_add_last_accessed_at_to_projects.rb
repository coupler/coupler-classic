Sequel.migration do
  up do
    [:projects, :projects_versions].each do |name|
      alter_table(name) { add_column(:last_accessed_at, Time) }
    end
  end

  down do
    [:projects, :projects_versions].each do |name|
      alter_table(name) { drop_column(:last_accessed_at) }
    end
  end
end
