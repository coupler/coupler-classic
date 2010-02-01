namespace :coupler do
  task :environment do
    require File.join(File.dirname(__FILE__), '..', 'lib', 'coupler')
  end

  task :test_env do
    ENV['COUPLER_ENV'] = "test"
  end
end
