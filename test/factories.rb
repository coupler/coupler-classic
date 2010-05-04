require 'factory_girl'

Factory.define :resource, :class => Coupler::Models::Resource do |r|
  r.sequence(:name) { |n| "Resource #{n}" }
  r.adapter "mysql"
  r.host "localhost"
  r.port 12345
  r.username "coupler"
  r.password "cupla"
  r.database_name "fake_data"
  r.table_name "people"
  r.association :project
end

Factory.define :project, :class => Coupler::Models::Project do |d|
  d.sequence(:name) { |n| "Project #{n}" }
end

Factory.define :transformation, :class => Coupler::Models::Transformation do |t|
  t.association :transformer
  t.association :resource
  t.field do |record|
    record.resource.fields_dataset.first rescue nil
  end
end

Factory.define :scenario, :class => Coupler::Models::Scenario do |s|
  s.sequence(:name) { |n| "Scenario #{n}" }
  s.association :project

  # FIXME: this is kind of crappy
  s.resource_1_id { |x| Factory(:resource, :project => x.project).id }
end

Factory.define :matcher, :class => Coupler::Models::Matcher do |m|
  m.association :scenario
  m.comparator_name 'exact'
  m.comparator_options do |matcher|
    matcher.scenario.resources.inject({}) do |hash, resource|
      hash[resource.id.to_s] = {'field_name' => 'last_name'}
      hash
    end
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
