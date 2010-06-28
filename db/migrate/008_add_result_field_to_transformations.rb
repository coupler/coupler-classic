Sequel.migration do
  up do
    [:transformations, :transformations_versions].each do |name|
      alter_table(name) do
        rename_column(:field_id, :source_field_id)
        add_column(:result_field_id, Integer)
        add_column(:position, Integer)
      end
      self[name].update(:result_field_id => :source_field_id)

      position = nil
      last_resource_id = nil
      self[name].order(:id).each do |record|
        if record[:resource_id] != last_resource_id
          position = 0
          last_resource_id = record[:resource_id]
        end
        position += 1
        self[name].filter(:id => record[:id]).update(:position => position)
      end
    end
  end

  down do
    [:transformations, :transformations_versions].each do |name|
      alter_table(name) do
        rename_column(:source_field_id, :field_id)
        drop_column(:result_field_id)
        drop_column(:position)
      end
    end
  end
end
