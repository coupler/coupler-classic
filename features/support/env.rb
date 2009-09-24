require File.dirname(__FILE__) + "/../../test/helper"
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
    Coupler::Base.set :environment, :test
    Coupler::Base
  end
end

World(CouplerWorld)
