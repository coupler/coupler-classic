namespace :web do
  desc "Start web server"
  task :start => ['db:start', 'coupler:environment'] do
    Coupler::Base.run!
  end
end
