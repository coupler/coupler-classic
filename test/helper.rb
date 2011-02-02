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

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
ENV['COUPLER_ENV'] = 'test'
require 'coupler'

Coupler::Base.set(:sessions, false) # workaround
Coupler::Base.set(:environment, :test)

class Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    Coupler::Base
  end

  def setup
    @original_database_count = Sequel::DATABASES.length
    @_database = Coupler::Database.instance
    @_database.tables.each do |name|
      next  if name == :schema_info
      @_database[name].delete
    end
  end

  def teardown
    if @tmpdirs
      @tmpdirs.each { |t| FileUtils.rm_rf(t) }
    end
    assert_equal @original_database_count, Sequel::DATABASES.length
  end

  def _connection_count
    Sequel::DATABASES.inject(0) { |sum, db| sum + db.pool.size }
  end

  def make_tmpdir(prefix = 'coupler')
    tmpdir = Dir.mktmpdir(prefix)
    @tmpdirs ||= []
    @tmpdirs << tmpdir
    tmpdir
  end
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

module
 VerboseConnectionMessages
  def self.extended(base)
    com.mysql.jdbc.Driver
    $conn = java.sql.DriverManager.getConnection("jdbc:mysql://localhost:12345/INFORMATION_SCHEMA?user=coupler&password=cupla");
  end

  def push(*args)
    super
    barf("push")
  end

  def delete(*args)
    super
    barf("delete")
  end

  private
    def barf(mog)
      puts "========== #{mog} =========="
      puts "COUNT: #{self.length}"

      stmt = $conn.createStatement
      rs = stmt.executeQuery("SHOW PROCESSLIST")
      count = 0
      while (rs.next) do
        count += 1
      end
      rs.close
      stmt.close

      puts "CONNECTIONS: #{count}"
      puts caller.join("\n")
    end
end
#Sequel::DATABASES.extend(VerboseConnectionMessages)

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

module Mocha
  class Expectation
    def yields_block_result(count = 1, &block)
      @yield_block_count = count
      @yield_block_proc = block
    end

    def invoke
      @invocation_count += 1
      perform_side_effects()
      if block_given? then
        if @yield_block_proc
          @yield_block_count.times do |i|
            yield(*@yield_block_proc.call(i))
          end
        else
          @yield_parameters.next_invocation.each do |yield_parameters|
            yield(*yield_parameters)
          end
        end
      end
      @return_values.next
    end
  end
end

require 'factory_girl'
Factory.find_definitions
