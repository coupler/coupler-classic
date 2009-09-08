$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../../lib')
require 'coupler'

require 'test/unit/assertions'
require 'webrat'

Webrat.configure do |config|
  config.mode = :sinatra
end

module CouplerWorld
  include Test::Unit::Assertions
  include Webrat::Methods
  include Webrat::Matchers

  def app
    Coupler.set :environment, :test
    Coupler
  end
end

World(CouplerWorld)
