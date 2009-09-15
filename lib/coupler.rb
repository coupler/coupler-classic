require 'sinatra/base'
require 'erb'
require 'sequel'

module Coupler
end

require File.dirname(__FILE__) + "/coupler/config"
require File.dirname(__FILE__) + "/coupler/database"
require File.dirname(__FILE__) + "/coupler/extensions"
require File.dirname(__FILE__) + "/coupler/base"
