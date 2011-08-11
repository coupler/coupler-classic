Sequel.migration do
  up do
    [:resources, :resources_versions].each do |name|
      add_column name, :status, String
    end
  end
end
