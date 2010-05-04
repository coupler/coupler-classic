class AddFieldIdToTransformations < Sequel::Migration
  def up
    alter_table(:transformations)          { add_column :field_id, :integer }
    alter_table(:transformations_versions) { add_column :field_id, :integer }

    db = Coupler::Database.instance
    fields = db[:fields]
    [:transformations, :transformations_versions].each do |name|
      ds = db[name]
      ds.each do |row|
        field = fields.filter({
          :resource_id => row[:resource_id],
          :name => row[:field_name]
        }).first
        ds.filter(:id => row[:id]).update(:field_id => field[:id])
      end
    end

    alter_table(:transformations)          { drop_column :field_name }
    alter_table(:transformations_versions) { drop_column :field_name }
  end

  def down
    alter_table(:transformations)          { add_column :field_name, String }
    alter_table(:transformations_versions) { add_column :field_name, String }

    db = Coupler::Database.instance
    fields = db[:fields]
    [:transformations, :transformations_versions].each do |name|
      ds = db[name]
      ds.each do |row|
        field = fields.filter({
          :resource_id => row[:resource_id],
          :id => row[:field_id]
        }).first
        ds.filter(:id => row[:id]).update(:field_name => field[:name])
      end
    end

    alter_table(:transformations)          { drop_column :field_id }
    alter_table(:transformations_versions) { drop_column :field_id }
  end
end
