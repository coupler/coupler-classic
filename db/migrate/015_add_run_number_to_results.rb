Sequel.migration do
  up do
    alter_table(:results) do
      drop_column(:score_set_id)
      add_column(:run_number, Integer)
    end
  end

  down do
    alter_table(:results) do
      drop_column(:run_number)
      add_column(:score_set_id, Integer)
    end
  end
end
