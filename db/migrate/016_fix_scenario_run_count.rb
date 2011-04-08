Sequel.migration do
  up do
    # Fix scenario run_count
    scenarios = self[:scenarios]
    ds = scenarios.join(:results, :scenario_id => :id)
    run_counts = ds.group_and_count(:scenario_id).all
    run_counts.each do |row|
      run_count = row[:count] > 1 ? 1 : 0
      scenarios.filter(:id => row[:scenario_id]).update(:run_count => run_count)
    end

    # Delete all but the last result, since the other ones were overwritten
    last_scenario_id = nil
    results = self[:results]
    results.order(:scenario_id, :id.desc).each do |result|
      if result[:scenario_id] != last_scenario_id
        last_scenario_id = result[:scenario_id]
        results.filter(:id => result[:id]).update(:run_number => 1)
      else
        results.filter(:id => result[:id]).delete
      end
    end
  end

  down do
  end
end
