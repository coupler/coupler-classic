require 'sinatra/base'
require 'rack/flash'
require 'erb'
require 'sequel'

module Coupler
end

require File.dirname(__FILE__) + "/coupler/config"
require File.dirname(__FILE__) + "/coupler/project"
require File.dirname(__FILE__) + "/coupler/resource"
require File.dirname(__FILE__) + "/coupler/transformation"

require File.dirname(__FILE__) + "/coupler/transformers"
require File.dirname(__FILE__) + "/coupler/extensions"
require File.dirname(__FILE__) + "/coupler/base"
