Factory.define :resource, :class => Coupler::Models::Resource do |r|
  r.name "testing"
  r.adapter "mysql"
  r.host "localhost"
  r.port 3306
  r.username "coupler"
  r.password "cupla"
  r.database_name "coupler_test"
  r.table_name "people"
  r.association :project
end

Factory.define :project, :class => Coupler::Models::Project do |d|
  d.name "Birth defects"
end
