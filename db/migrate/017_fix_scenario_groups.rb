Sequel.migration do
  up do
    db = self
    uri_template = db.uri.sub("coupler", "scenario_%d")
    scenario_dbs = {}
    db[:results].each do |result|
      run_number = result[:run_number]
      scenario_db = scenario_dbs[result[:scenario_id]] ||= Sequel.connect(uri_template % result[:scenario_id])
      groups_table = :"groups_#{run_number}"
      scenario_db.alter_table(groups_table) { add_column(:resource_id, Integer) }
      groups_ds = scenario_db[groups_table.as(:t1)]
      join_ds = groups_ds.select(:t1__id, :t2__resource_id).
        join(:"groups_records_#{run_number}", {:group_id => :id}, {:table_alias => :t2}).
        group(:t1__id, :t2__resource_id)
      join_ds.each do |row|
        groups_ds.filter(:id => row[:id]).update(:resource_id => row[:resource_id])
      end
    end
  end
  down do
    db = self
    uri_template = db.uri.sub("coupler", "scenario_%d")
    scenario_dbs = {}
    db[:results].each do |result|
      run_number = result[:run_number]
      scenario_db = scenario_dbs[result[:scenario_id]] ||= Sequel.connect(uri_template % result[:scenario_id])
      groups_table = :"groups_#{run_number}"
      scenario_db.alter_table(groups_table) { drop_column(:resource_id) }
    end
  end
end
