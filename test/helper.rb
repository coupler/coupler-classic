require 'java'
require 'test/unit'
require 'pp'
require 'rubygems'
require 'mocha'
require 'rack/test'
require 'rack/flash'
require 'rack/flash/test'
require 'nokogiri'
require 'timecop'
require 'ruby-debug'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
ENV['COUPLER_ENV'] = 'test'
require 'coupler/server'
require 'coupler'

class Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    Coupler::Base.set :environment, :test
    Coupler::Base
  end

  def setup
    @original_database_count = Sequel::DATABASES.length
  end

  def teardown
    database ||= Coupler::Database.instance
    database.tables.each do |name|
      database[name].delete
    end

    assert_equal @original_database_count, Sequel::DATABASES.length
  end
end

module VerboseConnectionMessages
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

require 'factory_girl'
Factory.definition_file_paths = [ File.dirname(__FILE__) + "/factories" ]
