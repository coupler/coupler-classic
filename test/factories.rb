require 'factory_girl'

Factory.define :connection, :class => Coupler::Models::Connection do |c|
  c.sequence(:name) { |n| "Connection #{n}" }
  c.adapter "mysql"
  c.host "localhost"
  c.port 12345
  c.username "coupler"
  c.password "cupla"
end

Factory.define :resource, :class => Coupler::Models::Resource do |r|
  r.sequence(:name) { |n| "Resource #{n}" }
  r.database_name "fake_data"
  r.table_name "people"
  r.association :connection
  r.association :project
end

Factory.define :project, :class => Coupler::Models::Project do |d|
  d.sequence(:name) { |n| "Project #{n}" }
end

Factory.define :transformation, :class => Coupler::Models::Transformation do |t|
  t.association :transformer
  t.association :resource
  t.source_field do |record|
    record.resource.fields_dataset.first rescue nil
  end
end

Factory.define :scenario, :class => Coupler::Models::Scenario do |s|
  s.sequence(:name) { |n| "Scenario #{n}" }
  s.association :project
  s.resource_1 { |x| x.project ? Factory(:resource, :project => x.project) : nil }
end

Factory.define :matcher, :class => Coupler::Models::Matcher do |m|
  m.association :scenario
  m.comparisons_attributes do |record|
    resources = record.scenario.resources
    [{
      'lhs_type' => 'field', 'lhs_value' => resources[0].fields_dataset.order('id DESC').last.id, 'lhs_which' => 1,
      'rhs_type' => 'field', 'rhs_value' => resources[-1].fields_dataset.order('id DESC').last.id, 'rhs_which' => 2,
      'operator' => 'equals'
    }]
  end
end

Factory.define :result, :class => Coupler::Models::Result do |r|
  r.association :scenario
end

Factory.define :resource_job, :class => Coupler::Models::Job do |j|
  j.name 'transform'
  j.status 'scheduled'
  j.association :resource
end

Factory.define :scenario_job, :class => Coupler::Models::Job do |j|
  j.name 'run_scenario'
  j.status 'scheduled'
  j.association :scenario
end

Factory.define :transformer, :class => Coupler::Models::Transformer do |t|
  t.sequence(:name) { |n| "Transformer #{n}" }
  t.code "value"
  t.allowed_types { |x| %w{string integer datetime} }
  t.result_type "same"
end

Factory.define :field, :class => Coupler::Models::Field do |f|
  f.sequence(:name) { |n| "field_#{n}" }
  f.add_attribute :type, "integer"
  f.db_type "int(11)"
  f.is_primary_key 0
  f.is_selected 1
  f.association :resource
end

Factory.define :comparison, :class => Coupler::Models::Comparison do |c|
  c.association :matcher
  c.lhs_type "integer"
  c.lhs_value 1
  c.rhs_type "integer"
  c.rhs_value 1
  c.operator "equals"
end

Factory.define :import, :class => Coupler::Models::Import do |i|
  i.data { fixture_file_upload('people.csv') }
  i.association :project
end
