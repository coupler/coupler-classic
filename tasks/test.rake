require 'rake/testtask'

desc "Run all tests"
task :test do
  errors = %w(test:unit test:functional test:integration).collect do |task|
    begin
      Rake::Task[task].invoke
      nil
    rescue => e
      task
    end
  end.compact
  abort "Errors running #{errors * ', '}!" if errors.any?
end

namespace :test do
  Rake::TestTask.new(:unit) do |test|
    test.libs << 'lib' << 'test'
    test.pattern = 'test/unit/**/test_*.rb'
    #test.verbose = true
    test.ruby_opts = %w{--debug}
  end
  task :unit => ['environment:test', 'db:purge', 'db:migrate', 'db:fake']

  Rake::TestTask.new(:integration) do |test|
    test.libs << 'lib' << 'test'
    test.pattern = 'test/integration/**/test_*.rb'
    #test.verbose = true
    test.ruby_opts = %w{--debug}
  end
  task :integration => ['environment:test', 'db:purge', 'db:migrate', 'db:fake']

  Rake::TestTask.new(:functional) do |test|
    test.libs << 'lib' << 'test'
    test.pattern = 'test/functional/**/test_*.rb'
    #test.verbose = true
    test.ruby_opts = %w{--debug}
  end
  task :functional => ['environment:test', 'db:purge', 'db:migrate', 'db:fake']
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

begin
  require 'cucumber/rake/task'
  require 'git'

  Cucumber::Rake::Task.new(:features)
  task :features => ['environment:test', 'db:purge', 'db:migrate', 'db:fake']

  Cucumber::Rake::Task.new(:features_html, "Run Cucumber features with HTML output") do |t|
    outfile = "pages/_posts/#{Date.today.to_s}-features.html"
    t.cucumber_opts = "--format Butternut::Formatter --out #{outfile} features"
  end
  task :features_html => ['environment:test', 'db:purge', 'db:migrate', 'db:fake']

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

