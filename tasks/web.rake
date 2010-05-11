namespace :web do
  desc "Start web server"
  task :start => ['db:start', 'environment'] do
    Coupler::Base.run!
  end

  desc "Start test web server"
  task :start_test => ['environment:test', 'db:start'] do
    Coupler::Base.run!
  end
end
