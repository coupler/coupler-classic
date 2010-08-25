require 'open-uri'
require 'tempfile'
require 'fileutils'

namespace :vendor do
  desc "Fetch vendor packages"
  task :fetch do
    # FIXME: There is some fast and loose code right here.
    require 'lib/coupler/config'

    Coupler::Config.each_vendor_lib do |name, info|
      type_dir = File.join(Dir.pwd, 'vendor', info[:type])
      destination = File.join(type_dir, info[:dir] || info[:filename])
      if File.exist?(destination)
        puts "Not downloading #{name}"
        next
      end

      puts "Downloading #{name}..."
      io = info[:filename] ? File.open(destination, "w") : Tempfile.new(name)
      io.write(open(info[:url]).read)
      io.close

      if info[:uncompress] != false
        case info[:filetype]
        when "tarball"
          `tar -xzf #{io.path} -C #{type_dir}`
        when "jar", "zip"
          FileUtils.mkdir(destination)
          Dir.chdir(destination) do
            if info[:filetype] == "jar"
              `jar -xf #{io.path}`
            else
              `unzip #{io.path}`
            end
          end
        end
        io.unlink
      end
      if info[:filename] && info[:symlink]
        Dir.chdir(type_dir) do
          FileUtils.ln_sf("./#{info[:filename]}", info[:symlink], :verbose => true)
        end
      end
    end
  end
end
