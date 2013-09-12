# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'coupler/version'

Gem::Specification.new do |gem|
  gem.name          = "coupler"
  gem.version       = Coupler::VERSION
  gem.authors       = ["Jeremy Stephens"]
  gem.email         = ["jeremy.f.stephens@vanderbilt.edu"]
  gem.description   = %q{TODO: Write a gem description}
  gem.summary       = %q{TODO: Write a gem summary}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency 'sinatra'
  gem.add_dependency 'sequel'
  gem.add_development_dependency 'bundler'
  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'sqlite3'
  gem.add_development_dependency 'test-unit'
  gem.add_development_dependency 'rack-test'
  gem.add_development_dependency 'mocha'
  gem.add_development_dependency 'guard'
  gem.add_development_dependency 'guard-test'
  gem.add_development_dependency 'guard-rack'
  gem.add_development_dependency 'guard-bundler'
  gem.add_development_dependency 'guard-shell'
  gem.add_development_dependency 'capybara'
  gem.add_development_dependency 'poltergeist'
  gem.add_development_dependency 'database_cleaner'
end
