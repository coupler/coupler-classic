require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
  test.ruby_opts = %w{--debug}
end
task :test => ['coupler:test_env', :check_dependencies, 'db:bootstrap', 'db:fake']

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

begin
  require 'cucumber/rake/task'
  require 'git'

  Cucumber::Rake::Task.new(:features)
  task :features => [:set_test_env, :check_dependencies, 'db:bootstrap', 'db:fake']

  Cucumber::Rake::Task.new(:features_html, "Run Cucumber features with HTML output") do |t|
    outfile = "pages/_posts/#{Date.today.to_s}-features.html"
    t.cucumber_opts = "--format Butternut::Formatter --out #{outfile} features"
  end
  task :features_html => [:set_test_env, :check_dependencies, 'db:bootstrap', 'db:fake']

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

