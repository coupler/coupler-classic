$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../../lib')
require 'coupler'

require 'test/unit/assertions'

World(Test::Unit::Assertions)
