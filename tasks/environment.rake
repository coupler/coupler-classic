task :environment do
  ENV['COUPLER_HOME'] = File.expand_path(File.join(File.dirname(__FILE__), '..'))
  require 'bundler'
  Bundler.setup(:default, :development)
  require File.join(File.dirname(__FILE__), '..', 'lib', 'coupler')
end

namespace :environment do
  task :test do
    ENV['COUPLER_ENV'] = "test"
    Rake::Task["environment"].execute
  end
end
