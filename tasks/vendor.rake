require 'open-uri'
require 'tempfile'
require 'fileutils'

namespace :vendor do
  desc "Fetch vendor packages"
  task :fetch do
    require 'lib/coupler/config'

    Coupler::Config.each_vendor_lib do |name, type, filetype, dir, url|
      destination = File.join('vendor', type, dir)
      next if File.exist?(destination)

      puts "Downloading #{name}..."
      tmp = Tempfile.new(name)
      tmp.write(open(url).read)
      tmp.close

      case filetype
      when "tarball"
        `tar -xzf #{tmp.path} -C #{File.join('vendor', type)}`
      when "jar", "zip"
        FileUtils.mkdir(destination)
        Dir.chdir(destination) do
          if filetype == "jar"
            `jar -xf #{tmp.path}`
          else
            `unzip #{tmp.path}`
          end
        end
      end

      tmp.unlink
    end
  end
end
