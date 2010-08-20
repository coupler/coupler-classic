Sequel.migration do
  up do
    [:resources, :resources_versions].each do |name|
      alter_table(name) { add_column(:transformed_with, String) }
    end
  end

  down do
    [:resources, :resources_versions].each do |name|
      alter_table(name) { drop_column(:transformed_with) }
    end
  end
end
