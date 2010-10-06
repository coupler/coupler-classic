Sequel.migration do
  up do
    [:scenarios, :scenarios_versions].each do |name|
      alter_table(name) { add_column(:run_count, Integer, :default => 0) }
    end
  end

  down do
    [:scenarios, :scenarios_versions].each do |name|
      alter_table(name) { drop_column(:run_count) }
    end
  end
end
