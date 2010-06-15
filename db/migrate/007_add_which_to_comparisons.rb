Sequel.migration do
  up do
    alter_table :comparisons do
      add_column :lhs_which, Integer
      add_column :rhs_which, Integer
    end
    ds = self[:comparisons].
      select(:comparisons__id).
      join(:matchers, :matchers__id => :comparisons__matcher_id).
      join(:scenarios, :scenarios__id => :matchers__scenario_id).
      filter(:scenarios__resource_2_id => nil)
    ids = ds.all.collect { |x| x[:id] }
    self[:comparisons].filter(:id => ids, :lhs_type => 'field').update(:lhs_which => 1)
    self[:comparisons].filter(:id => ids, :rhs_type => 'field').update(:rhs_which => 2)
  end

  down do
    alter_table :comparisons do
      drop_column :lhs_which
      drop_column :rhs_which
    end
  end
end
