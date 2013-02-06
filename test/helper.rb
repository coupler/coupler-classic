require 'java'
require 'pp'
require 'yaml'
require 'erb'
require 'tempfile'
require 'tmpdir'
require 'fileutils'

require 'rubygems'
require 'bundler'
Bundler.require(:default, :development)

require 'mocha/setup'
require 'rack/test'
require 'sequel/extensions/schema_dumper'

dir = File.dirname(__FILE__)
$LOAD_PATH.unshift(dir)

# set here and in the rake environment task
ENV['COUPLER_ENV'] = 'test'
ENV['COUPLER_HOME'] = File.expand_path(File.join(dir, '..'))

$LOAD_PATH.unshift(File.join(dir, '..', 'lib'))
require 'coupler'

Coupler::Base.set(:sessions, false) # workaround
Coupler::Base.set(:environment, :test)
p Sequel::DATABASES
Coupler::Database.migrate!

#Capybara.register_driver :selenium_chrome do |app|
  #Capybara::Driver::Selenium.new(app, :browser => :chrome)
#end
Capybara.javascript_driver = :selenium
Capybara.app = Coupler::Base

module Coupler
  module Test
    class Base < ::Test::Unit::TestCase
      include Coupler
      include Coupler::Models
      @@test_config = YAML.load(ERB.new(File.read(File.join(File.dirname(__FILE__), 'config.yml'))).result(binding))

      def setup
        #@_original_connection_count = connection_count
        @_database = Coupler::Database
        @_database.tables.each do |name|
          next  if name == :schema_info
          @_database[name].delete
        end
      end

      def teardown
        if @_tmpdirs
          @_tmpdirs.each { |t| FileUtils.rm_rf(t) }
        end
        # FIXME: this fails a lot, probably for the wrong reason
        #assert_equal @_original_connection_count, connection_count,
          #Sequel::DATABASES.select { |db| db.pool.size > 0 }.collect { |db| db.inspect }.inspect
      end

      def connection_count
        Sequel::DATABASES.inject(0) { |sum, db| sum + db.pool.size }
      end

      def make_tmpdir(prefix = 'coupler')
        tmpdir = Dir.mktmpdir(prefix)
        @_tmpdirs ||= []
        @_tmpdirs << tmpdir
        tmpdir
      end

      def fixture_path(name)
        File.join(File.dirname(__FILE__), "fixtures", name)
      end

      def fixture_file_upload(name, mime_type = "text/plain")
        file_upload(fixture_path(name), mime_type)
      end

      def file_upload(file, mime_type = "text/plain")
        Rack::Test::UploadedFile.new(file, mime_type)
      end

      def fixture_file(name)
        File.open(fixture_path(name))
      end

      # connection helpers
      def self.each_adapter(&block)
        @@test_config.each_pair { |k, v| block.call(k, v) }
      end

      def each_adapter(&block)
        self.class.each_adapter(&block)
      end

      def self.adapter_test(adapter, description, &block)
        test("#{description} for #{adapter} adapter", &block)
      end

      def self.new_connection(adapter, attribs = {})
        Coupler::Models::Connection.new(
          @@test_config[adapter].merge(:adapter => adapter).update(attribs))
      end

      def new_connection(*args)
        self.class.new_connection(*args)
      end
    end

    class UnitTest < Base; end
    class IntegrationTest < Base; end

    class FunctionalTest < Base
      include Capybara::DSL

      def app
        Coupler::Base
      end

      def teardown
        super
        Capybara.reset_sessions!
        Capybara.use_default_driver
      end

      def setup
        if attributes[:javascript]
          Capybara.current_driver = Capybara.javascript_driver
        end
        super
      end
    end
  end
end

# deep case equality
class Hash
  def ===(other)
    if other.is_a?(Hash)
      return false  if keys.length != other.keys.length
      all? { |(key, value)| value === other[key] }
    else
      super
    end
  end
end

class Array
  def ===(other)
    if other.is_a?(Array)
      return false  if length != other.length
      enum_for(:each_with_index).all? { |value, index| value === other[index] }
    else
      super
    end
  end
end
