ENV['GEM_HOME'] = ARGV[0]

require 'rubygems'
require 'rubygems/dependency_installer'
require 'rubygems/remote_fetcher'

spec = Gem::Specification.load(File.join(File.dirname(__FILE__), "..", "coupler.gemspec"))
inst = Gem::DependencyInstaller.new#({
  #:cache_dir => destination,
  #:install_dir => destination
#})
spec.runtime_dependencies.each do |dep|
  puts "Installing #{dep.name} and its dependencies"
  inst.install(dep.name, dep.version_requirements)
end
