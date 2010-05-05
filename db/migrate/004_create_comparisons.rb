class CreateComparisons < Sequel::Migration
  def up
    create_table :comparisons do
      primary_key :id
      Integer :matcher_id
      Integer :matcher_version
      Integer :field_1_id
      Integer :field_2_id
      Time :created_at
      Time :updated_at
    end

    [:matchers, :matchers_versions].each do |name|
      alter_table(name) do
        drop_column :comparator_options
      end
    end
  end

  def down
    [:matchers, :matchers_versions].each do |name|
      alter_table(name) do
        add_column :comparator_options, :text
      end
    end
    drop_table :comparisons
  end
end
