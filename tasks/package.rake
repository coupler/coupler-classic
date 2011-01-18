require 'ant'

namespace :package do
  build_dir = "build"
  gem_inst_dir = File.join(build_dir, "gems")
  gem_source_dir = File.join(gem_inst_dir, "jruby", "1.8", "gems")
  root_dir = File.join(build_dir, "root")
  licenses_dir = File.join(root_dir, "licenses")
  coupler_home = File.join(root_dir, "META-INF", "coupler.home")
  site_lib_dir = File.join(root_dir, "META-INF", "jruby.home", "lib", "ruby", "site_ruby", "1.8")
  jruby_jar = File.join("vendor", "java", "jruby-complete.jar")

  coupler_version = nil

  task :init do
    FileUtils.mkdir_p(gem_inst_dir)
    FileUtils.mkdir_p(coupler_home)
    FileUtils.mkdir_p(licenses_dir)
    coupler_version = `git rev-parse HEAD`

    ant.unjar :src => jruby_jar, :dest => root_dir
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
    end
  end

  task :copy_libs => :install_gems do
    ant.copy :todir => site_lib_dir do
      fileset :dir => gem_source_dir do
        include :name => "*/lib/**/*"
      end
      mapper :type => "regexp", :from => '^[^/]+/lib/(.+)$$', :to => '\1'
    end
    json_ext_dir = File.join(site_lib_dir, 'json', 'ext')
    parser_jar = File.join(json_ext_dir, 'parser.jar')
    generator_jar = File.join(json_ext_dir, 'generator.jar')
    ant.unjar :src => parser_jar, :dest => site_lib_dir do
      patternset { exclude(:name => "META-INF") }
    end
    ant.unjar :src => generator_jar, :dest => site_lib_dir do
      patternset { exclude(:name => "META-INF") }
    end
    FileUtils.rm([parser_jar, generator_jar])

    ant.copy :todir => coupler_home do
      fileset :dir => "." do
        include :name => "lib/**/*"
        include :name => "webroot/**/*"
        include :name => "db/migrate/*"
        include :name => "README.rdoc"
      end
    end
  end

  task :compile_runner => :init do
    ant.javac :srcdir => "src", :destdir => root_dir, :classpath => jruby_jar do
      compilerarg :value => "-Xlint:deprecation"
      compilerarg :value => "-Xlint:unchecked"
    end
    runner_path = File.join(root_dir, "edu", "vanderbilt", "coupler")
    ant.propertyfile :file => File.join(runner_path, "coupler.properties") do
      entry :key => "coupler.version", :value => coupler_version
      entry :key => "build.timestamp", :value => Time.now.utc.strftime('%y-%m-%d %H:%M %Z')
    end
    ant.copy :file => "src/edu/vanderbilt/coupler/jruby.properties", :todir => runner_path
  end

  task :copy_licenses => :install_gems do
    ant.copy :todir => licenses_dir do
      fileset :dir => gem_source_dir do
        include :name => "*/*LICENSE*"
      end
      mapper :type => "regexp", :from => '^(.+?)-\d[^/]+/.+$$', :to => '\1.license'
    end
    ant.copy :todir => licenses_dir do
      fileset :dir => gem_source_dir do
        include :name => "*/*COPYING*"
      end
      mapper :type => "regexp", :from => '^(.+?)-\d[^/]+/.+$$', :to => '\1.copying'
    end
    ant.copy :todir => licenses_dir do
      fileset :dir => "misc", :includes => "*.license"
    end
    ant.copy :file => "LICENSE", :tofile => File.join(licenses_dir, "coupler.license")
  end

  task :dist => [:copy_libs, :compile_runner, :copy_licenses, :environment] do
    coupler_version_short = coupler_version[0..6]
    ant.jar :destfile => File.join(build_dir, "coupler-#{coupler_version[0..6]}.jar"), :basedir => root_dir do
      manifest do
        attribute :name => "Main-Class", :value => "edu.vanderbilt.coupler.Main"
      end

      Coupler::Config.vendor_lib_paths('mysql-connector-java').each do |path|
        zipfileset :src => path
      end
      Coupler::Config.vendor_lib_paths('mysql-connector-mxj').each do |path|
        zipfileset :src => path
      end
    end
  end

  #<target name="clean" description="clean up">
    #<delete dir="${build}"/>
  #</target>
end
