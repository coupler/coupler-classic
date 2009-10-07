Factory.define :resource, :class => Coupler::Resource do |r|
  r.name "unicorns"
  r.adapter "mysql"
  r.host "localhost"
  r.port 3306
  r.username "coupler"
  r.password "omgponies"
  r.database_name "foo"
  r.table_name "bar"
  r.association :project
end

Factory.define :project, :class => Coupler::Project do |d|
  d.name "Birth defects"
end
