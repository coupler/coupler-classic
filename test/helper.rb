require 'rubygems'
require 'test/unit'
require 'rack/test'
require 'nokogiri'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'coupler'

class Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    Coupler.set :environment, :test
    Coupler
  end
end
