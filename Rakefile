require 'rubygems'
require 'rake'
require 'sequel'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "coupler"
    gem.summary = %Q{TODO: one-line summary of your gem}
    gem.description = %Q{TODO: longer description of your gem}
    gem.email = "viking415@gmail.com"
    gem.homepage = "http://github.com/coupler/coupler"
    gem.authors = ["Jeremy Stephens"]
    gem.add_development_dependency "cucumber"
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: sudo gem install jeweler"
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'test'
    test.pattern = 'test/**/test_*.rb'
    test.verbose = true
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
  end
end

task :test => :check_dependencies

begin
  require 'cucumber/rake/task'
  require 'git'

  Cucumber::Rake::Task.new(:features)
  task :features => :check_dependencies

  Cucumber::Rake::Task.new(:features_html, "Run Cucumber features with HTML output") do |t|
    outfile = "pages/_posts/#{Date.today.to_s}-features.html"
    t.cucumber_opts = "--format Coupler::JekyllFormatter --out #{outfile} features"
  end
  task :features_html => :check_dependencies

  desc "Update github pages for coupler"
  task :update_pages => :features_html do
    repos = Git.open("pages")
    repos.add('.')
    repos.commit("Added post (from Rake task)")
    repos.push
  end

rescue LoadError
  task :features do
    abort "Cucumber is not available. In order to run features, you must: sudo gem install cucumber"
  end
end

task :default => :test

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  if File.exist?('VERSION')
    version = File.read('VERSION')
  else
    version = ""
  end

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "coupler #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

desc "Bootstrap coupler"
task :bootstrap do
  require 'jdbc/mysql'
  require File.dirname(__FILE__) + "/vendor/mysql-connector-mxj-gpl-5-0-9/mysql-connector-mxj-gpl-5-0-9.jar"
  require File.dirname(__FILE__) + "/vendor/mysql-connector-mxj-gpl-5-0-9/mysql-connector-mxj-gpl-5-0-9-db-files.jar"
  require File.dirname(__FILE__) + "/vendor/mysql-connector-mxj-gpl-5-0-9/lib/aspectjrt.jar"

  dir = java.io.File.new(File.join(File.dirname(__FILE__), "db"))
  options = java.util.HashMap.new({
    'port' => '12345',
    'initialize-user' => 'true',
    'initialize-user.user' => 'coupler',
    'initialize-user.password' => 'cupla'
  })
  server = com.mysql.management.MysqldResource.new(dir)
  server.start("coupler-bootstrap", options)

  begin
    db = Sequel.connect("jdbc:mysql://localhost:12345/coupler?user=coupler&password=cupla&createDatabaseIfNotExist=true")
    db['SELECT VERSION()'].each do |row|
      p row
    end
  ensure
    server.shutdown
  end
end

begin
  require 'forgery'
  desc "Prepare test database"
  task :prepare do
    f = Tempfile.new("coupler_test")
    f.print DATA
    f.close

    `mysql -u root -p < #{f.path}`

    db = Sequel.connect("jdbc:mysql://localhost/coupler_test?user=coupler&password=cupla")
    people = db[:people]
    500.times do |i|
      people.insert({
        :first_name => Forgery(:name).first_name,
        :last_name  => Forgery(:name).last_name
      })
    end
  end
rescue LoadError
  task :prepare do
    abort "Forgery is not available. In order to run prepare, you must: sudo gem install forgery"
  end
end

__END__
DROP DATABASE IF EXISTS coupler_test;
CREATE DATABASE coupler_test;
GRANT ALL PRIVILEGES ON coupler_test.* to coupler@localhost identified by 'cupla';

USE coupler_test;
CREATE TABLE people (
  id INT NOT NULL AUTO_INCREMENT,
  first_name VARCHAR(50),
  last_name VARCHAR(50),
  PRIMARY KEY(id)
)
