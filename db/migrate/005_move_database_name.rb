class MoveDatabaseName < Sequel::Migration
  def up
    [:resources, :resources_versions].each do |name|
      alter_table(name) { add_column(:database_name, String) }
    end

    self[:connections].each do |connection|
      [:resources, :resources_versions].each do |name|
        self[name].filter(:connection_id => connection[:id]).update(:database_name => connection[:database_name])
      end
    end

    alter_table(:connections) { drop_column(:database_name) }
  end

  def down
    raise "This migration is not reversible."
  end
end
