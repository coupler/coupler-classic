require 'rubygems'
require 'rake'
require 'sequel'

desc "Load coupler environment"
task :environment do
  require File.join(File.dirname(__FILE__), 'lib', 'coupler')
end

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

namespace :db do
  desc "Start server daemon"
  task :start => :environment do
    server = Coupler::Server.instance
    server.start
  end

  desc "Stop server daemon"
  task :stop => :environment do
    server = Coupler::Server.instance
    server.shutdown
  end

  begin
    require 'forgery'
    desc "Create database with fake data"
    task :fake => [:environment, :start] do
      server = Coupler::Server.instance
      db = Sequel.connect(server.connection_string("fake_data", :create_database => true))
      db.tables.each { |t| db.drop_table(t) }
      db.create_table :people do
        primary_key :id
        String :first_name
        String :last_name
      end
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
end
