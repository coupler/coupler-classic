require File.dirname(__FILE__) + "/../../test/helper"
require 'test/unit/assertions'
require 'butternut'

module CouplerWorld
  include Test::Unit::Assertions

  def app
    Coupler::Base.set :environment, :test
    Coupler::Base
  end
end

Before do
  database = Coupler::Database.instance
  database.tables.each { |t| database[t].delete }
end

Butternut.setup_hooks(self)
World(CouplerWorld, Butternut::Helpers)
