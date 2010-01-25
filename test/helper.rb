require 'java'
require 'test/unit'
require 'pp'
require 'rubygems'
require 'mocha'
require 'active_support'
require 'active_support/test_case'
require 'rack/test'
require 'rack/flash'
require 'rack/flash/test'
require 'nokogiri'
require 'timecop'
#require 'ruby-debug'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
ENV['COUPLER_ENV'] = 'test'
require 'coupler'

class ActiveSupport::TestCase < ::Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    Coupler::Base.set :environment, :test
    Coupler::Base
  end

  def teardown
    nuke_tables
  end

  def nuke_tables
    @__database ||= Coupler::Database.instance
    @__database.tables.each do |name|
      #puts "DELETE FROM #{name}"
      @__database[name].delete
    end
  end

  #def run(*args, &block)
    #Coupler::Database.instance.transaction do
      #super
      #raise Sequel::Rollback
    #end
  #end
end

require 'factory_girl'
Factory.definition_file_paths = [ File.dirname(__FILE__) + "/factories" ]
