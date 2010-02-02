namespace :web do
  desc "Start web server"
  task :start => ['db:start', 'coupler:environment'] do
    Coupler::Base.run!
  end

  desc "Start test web server"
  task :start_test => ['coupler:test_env', 'db:start', 'coupler:environment'] do
    Coupler::Base.run!
  end
end
