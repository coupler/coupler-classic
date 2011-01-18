task :environment do
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
