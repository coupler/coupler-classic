class CreateFields < Sequel::Migration
  def up
    [:fields, :fields_versions].each do |name|
      create_table(name) do
        primary_key :id
        String :name
        String :type
        String :db_type
        Boolean :primary_key
        Boolean :selected, :default => true
        Integer :resource_id
        Integer :version, :default => 0
        Integer :current_id   if name.to_s =~ /_versions$/
        Time :created_at
        Time :updated_at
      end
    end

    fields = Coupler::Database.instance[:fields]
    fields_versions = Coupler::Database.instance[:fields_versions]
    Coupler::Models::Resource.each do |resource|
      select = resource.select || []
      now = Time.now

      resource.source_schema.each do |(name, info)|
        hash = {
          :name => name.to_s,
          :type => info[:type].to_s,
          :db_type => info[:db_type],
          :primary_key => info[:primary_key] ? 1 : 0,
          :selected => resource.select.include?(name.to_s) ? 1 : 0,
          :resource_id => resource.id,
          :version => 1,
          :created_at => now,
          :updated_at => now
        }
        id = fields.insert(hash)
        fields_versions.insert(hash.merge(:current_id => id))
      end
    end

    [:resources, :resources_versions].each do |name|
      alter_table(name) do
        drop_column :select
      end
    end
  end

  def down
    [:resources, :resources_versions].each do |name|
      alter_table(name) do
        add_column :select, :text
      end
    end
    resources = Coupler::Database.instance[:resources]
    resources_versions = Coupler::Database.instance[:resources_versions]
    Coupler::Models::Resource.each do |resource|
      select = resource.fields_dataset.filter(:selected => 1).collect(&:name)
      dump = [Marshal.dump(select)].pack('m')
      resources.filter(:id => resource.id).update(:select => dump)
      resources_versions.filter(:current_id => resource.id, :version => resource.version).update(:select => dump)
    end

    drop_table(:fields, :fields_versions)
  end
end
