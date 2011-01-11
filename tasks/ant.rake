require 'ant'
require 'git'

namespace :package do
  build_dir = "build"
  gems_dir = File.join(build_dir, "gems")
  coupler_home = File.join(build_dir, "root", "META-INF", "coupler.home")
  coupler_version = nil
  coupler_version_short = nil

  task :init do
    ant.mkdir :dir => gems_dir
    ant.mkdir :dir => File.join(build_dir, "ruby")
    ant.mkdir :dir => File.join(build_dir, "root", "licenses")
    ant.mkdir :dir => File.join(build_dir, "gems")
    ant.mkdir :dir => coupler_home

    repos = Git.open('.')
    coupler_version = repos.revparse("HEAD")
    coupler_version_short = coupler_version[0..6]
  end

  task :install_gems => :init do
    Bundler::Installer.install(Pathname.new(gems_dir), Bundler.definition, { :production => true })
  end
end
