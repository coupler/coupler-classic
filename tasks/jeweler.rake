begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "coupler"
    gem.summary = %Q{Coupler is an application for linking data}
    gem.description = %Q{Coupler is an application based on Sinatra and JRuby for linking data}
    gem.email = "jeremy.f.stephens@vanderbilt.edu"
    gem.homepage = "http://github.com/coupler/coupler"
    gem.authors = ["Jeremy Stephens"]
    gem.platform = "java"
    gem.files.exclude /\.git(ignore|modules)/, "vendor/960-grid-system", "gfx"
    gem.executables = ["coupler"]
    gem.add_dependency "sinatra"
    gem.add_dependency "rack-flash"
    gem.add_dependency "jdbc-mysql"
    gem.add_dependency "sequel"
    gem.add_dependency "json-jruby"
    gem.add_development_dependency "mocha"
    gem.add_development_dependency "cucumber"
    gem.add_development_dependency "rack-test"
    gem.add_development_dependency "nokogiri"
    gem.add_development_dependency "timecop"
    gem.add_development_dependency "butternut"
    gem.add_development_dependency "forgery"
    gem.add_development_dependency "factory_girl"
  end
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: sudo gem install jeweler"
end
