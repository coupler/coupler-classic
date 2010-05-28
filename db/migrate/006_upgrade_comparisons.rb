class UpgradeComparisons < Sequel::Migration
  def marshal(v)
    [Marshal.dump(v)].pack('m')
  end

  def up
    alter_table(:comparisons) do
      add_column :lhs_type, String
      add_column :lhs_value, String
      add_column :operator, String
      add_column :rhs_type, String
      add_column :rhs_value, String
    end
    dataset = self[:comparisons]
    dataset.each do |comparison|
      dataset.filter(:id => comparison[:id]).update({
        :lhs_type => "field", :lhs_value => marshal(comparison[:field_1_id]),
        :rhs_type => "field", :rhs_value => marshal(comparison[:field_2_id]),
        :operator => "equals"
      })
    end
    alter_table(:comparisons) do
      drop_column :field_1_id
      drop_column :field_2_id
    end

    alter_table(:matchers) { drop_column(:comparator_name) }
    alter_table(:matchers_versions) { drop_column(:comparator_name) }
  end

  def down
    raise "This migration is not reversible."
  end
end
