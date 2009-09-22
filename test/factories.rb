Factory.define :database, :class => Coupler::Database do |d|
  d.name "unicorns"
  d.adapter "mysql"
  d.host "localhost"
  d.port 3306
  d.username "coupler"
  d.password "omgponies"
  d.dbname "foo"
end
