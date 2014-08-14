require 'lotus'
require 'lotus/model'
require 'yaml'

module Coupler
  class Application < Lotus::Application
    attr_reader :mapper, :adapter

    configure do
      layout :application
      routes 'config/routes'
      mapping 'config/mapping'

      load_paths << 'app'

      controller_pattern "%{controller}Controller::%{action}"
      view_pattern       "%{controller}::%{action}"
    end

    def initialize
      super
      configure_mapper
      configure_adapter
      configure_repositories
    end

    private

    def configure_mapper
      @mapper = Lotus::Model::Mapper.new(&configuration.mapping.to_proc)
      @mapper.load!
    end

    def configure_adapter
      config = YAML.load_file(File.expand_path('../config/adapter.yml', __FILE__))
      env = Lotus::Environment.new
      info = config[env.environment]

      klass =
        case info['adapter']
        when 'memory'
          require 'lotus/model/adapters/memory_adapter'
          Lotus::Model::Adapters::MemoryAdapter
        when 'sql'
          require 'lotus/model/adapters/sql_adapter'
          Lotus::Model::Adapters::SqlAdapter
        end

      @adapter = klass.new(mapper, info['uri'])
    end

    def configure_repositories
      Coupler.constants.each do |name|
        if name.to_s =~ /Repository$/
          Coupler.const_get(name).adapter = adapter
        end
      end
    end
  end
end
