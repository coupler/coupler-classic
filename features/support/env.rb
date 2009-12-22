require File.dirname(__FILE__) + "/../../test/helper"
require 'test/unit/assertions'
require '/home/stephej1/Projects/butternut/lib/butternut'

module CouplerWorld
  include Test::Unit::Assertions

  def app
    Coupler::Base.set :environment, :test
    Coupler::Base
  end
end

Before do
  config = Coupler::Config.instance
  config.tables.each { |t| config[t].delete }
end

Butternut.setup_hooks(self)
World(CouplerWorld, Butternut::Helpers)
