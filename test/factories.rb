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
  t.field_name 'first_name'
  t.transformer_name 'downcaser'
  t.association :resource
end
