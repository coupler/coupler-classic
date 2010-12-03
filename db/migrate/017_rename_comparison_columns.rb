Sequel.migration do
  up do
    alter_table(:comparisons) do
      rename_column :lhs_value, :raw_lhs_value
      rename_column :rhs_value, :raw_rhs_value
    end
  end
  down do
    alter_table(:comparisons) do
      rename_column :raw_lhs_value, :lhs_value
      rename_column :raw_rhs_value, :rhs_value
    end
  end
end
