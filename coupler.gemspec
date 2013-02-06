# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'coupler/version'

Gem::Specification.new do |gem|
  gem.name          = "coupler"
  gem.version       = Coupler::VERSION
  gem.authors       = ["Jeremy Stephens"]
  gem.email         = ["jeremy.f.stephens@vanderbilt.edu"]
  gem.description   = %q{Coupler is a (JRuby) desktop application designed to link datasets together}
  gem.summary       = %q{Coupler is a desktop application for linking datasets together}
  gem.homepage      = "http://github.com/coupler/coupler"
  gem.licenses      = ["MIT"]

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_runtime_dependency 'rack'
  gem.add_runtime_dependency 'sinatra'
  gem.add_runtime_dependency 'sequel'
  gem.add_runtime_dependency 'sinatra-flash'
  gem.add_runtime_dependency 'json'
  gem.add_runtime_dependency 'fastercsv'
  gem.add_runtime_dependency 'carrierwave-sequel'
  gem.add_runtime_dependency 'mizuno'
  gem.add_runtime_dependency 'jdbc-h2'
end
