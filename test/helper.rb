require 'rubygems'
require 'test/unit'
require 'rack/test'
require 'nokogiri'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
ENV['COUPLER_ENV'] = 'test'
require 'coupler'

class Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    Coupler::Base.set :environment, :test
    Coupler::Base
  end
end

Sequel::Model::InstanceMethods.send(:alias_method, :save!, :save)

require 'factory_girl'
Factory.definition_file_paths = [ File.dirname(__FILE__) + "/factories" ]
