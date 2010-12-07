Sequel.migration do
  up do
    Coupler::Models::Scenario.each do |scenario|
      scenario.set_linkage_type
      scenario.save
    end
  end
end
