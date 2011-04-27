require 'ant'

namespace :package do
  build_dir = "build"
  gem_inst_dir = File.join(build_dir, "gems")
  coupler_home = File.join(build_dir, "coupler")

  coupler_version = nil

  task :init do
    FileUtils.mkdir_p(gem_inst_dir)
    FileUtils.mkdir_p(coupler_home)
    coupler_version = `git rev-parse HEAD`
  end

  task :install_gems => :init do
    require 'bundler'

    begin
      Bundler.settings[:path] = gem_inst_dir
      Bundler.settings[:disable_shared_gems] = '1'
      Bundler.settings.without = [:development]

      Bundler::Installer.install(Bundler.root, Bundler.definition, { :path => gem_inst_dir, :without => [:development], :local => false })
    ensure
      Bundler.settings[:path] = nil
      Bundler.settings[:disable_shared_gems] = nil
      Bundler.settings.without = []
      ant.delete :dir => '.bundle'
    end
  end

  task :create_dependency_jar => [:install_gems, :environment] do
    ant.jar :destfile => File.join(build_dir, "coupler-dependencies-#{coupler_version[0..6]}.jar"), :basedir => gem_inst_dir do
      Coupler::Config.vendor_lib_paths('mysql-connector-java').each do |path|
        zipfileset :src => path
      end
      Coupler::Config.vendor_lib_paths('mysql-connector-mxj').each do |path|
        zipfileset :src => path
      end
    end
  end

  task :create_coupler_jar => :init do
    ant.jar({
      :destfile => File.join(build_dir, "coupler-#{coupler_version[0..6]}.jar"),
      :basedir => '.',
      :includes => "lib/**/* webroot/**/* db/migrate/* README.rdoc"
    })
  end

  desc "Create a distributable JAR"
  task :dist => [:create_dependency_jar, :create_coupler_jar]

  task :clean do
    ant.delete :dir => build_dir
  end
end
