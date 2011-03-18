require 'java'
require 'pp'

require 'rubygems'
require 'bundler'
Bundler.setup(:default, :development)

require 'test/unit'
require 'mocha'
require 'rack/test'
require 'rack/flash'
require 'rack/flash/test'
require 'nokogiri'
require 'timecop'
require 'tempfile'
require 'tmpdir'
require 'fileutils'
require 'table_maker'
require 'sequel'
require 'sequel/extensions/schema_dumper'

dir = File.dirname(__FILE__)
$LOAD_PATH.unshift(dir)
require 'table_sets'

$LOAD_PATH.unshift(File.join(dir, '..', 'lib'))
ENV['COUPLER_ENV'] = 'test'
require 'coupler'

Coupler::Base.set(:sessions, false) # workaround
Coupler::Base.set(:environment, :test)

class Test::Unit::TestCase
  include Rack::Test::Methods
  extend TableSets

  def app
    Coupler::Base
  end

  def self.startup
    Coupler::Database.instance.migrate!
    @@test_database = Sequel.connect(Coupler::Base.connection_string("coupler_test_data"))
  end

  def self.shutdown
    @@test_database.disconnect
  end

  def self.test_database
    @@test_database
  end

  def test_database
    self.class.test_database
  end

  def setup
    @_original_connection_count = connection_count
    @_database = Coupler::Database.instance
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

require 'factory_girl'
Factory.find_definitions
