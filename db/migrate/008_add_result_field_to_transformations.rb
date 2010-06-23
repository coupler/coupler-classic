Sequel.migration do
  up do
    [:transformations, :transformations_versions].each do |name|
      alter_table(name) do
        rename_column(:field_id, :source_field_id)
        add_column(:result_field_id, Integer)
      end
    end
  end

  down do
    [:transformations, :transformations_versions].each do |name|
      alter_table(name) do
        rename_column(:source_field_id, :field_id)
        drop_column(:result_field_id)
      end
    end
  end
end
