# encoding: utf-8

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "coupler"
  gem.homepage = "http://github.com/coupler/coupler"
  gem.license = "MIT"
  gem.summary = %Q{Coupler is a desktop application for linking datasets together}
  gem.description = %Q{Coupler is a (JRuby) desktop application designed to link datasets together}
  gem.email = "jeremy.f.stephens@vanderbilt.edu"
  gem.authors = ["Jeremy Stephens"]
  gem.platform = 'java'
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new

#require 'rake/testtask'
#Rake::TestTask.new(:test) do |test|
  #test.libs << 'lib' << 'test'
  #test.pattern = 'test/**/test_*.rb'
  #test.verbose = true
#end

#require 'rcov/rcovtask'
#Rcov::RcovTask.new do |test|
  #test.libs << 'test'
  #test.pattern = 'test/**/test_*.rb'
  #test.verbose = true
  #test.rcov_opts << '--exclude "gems/*"'
#end

#task :default => :test

#require 'rake/rdoctask'
#Rake::RDocTask.new do |rdoc|
  #version = File.exist?('VERSION') ? File.read('VERSION') : ""

  #rdoc.rdoc_dir = 'rdoc'
  #rdoc.title = "coupler #{version}"
  #rdoc.rdoc_files.include('README*')
  #rdoc.rdoc_files.include('lib/**/*.rb')
#end
