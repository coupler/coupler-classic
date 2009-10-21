require 'rubygems'
require 'sinatra/base'
require 'rack/flash'
require 'erb'
require 'sequel'
require 'singleton'

module Coupler
  ROOT = File.expand_path(File.join(File.dirname(__FILE__), ".."))
end

COUPLER_ENV = ENV['COUPLER_ENV']

require File.dirname(__FILE__) + "/coupler/server"
require File.dirname(__FILE__) + "/coupler/config"
require File.dirname(__FILE__) + "/coupler/project"
require File.dirname(__FILE__) + "/coupler/resource"
require File.dirname(__FILE__) + "/coupler/transformation"

require File.dirname(__FILE__) + "/coupler/transformers"
require File.dirname(__FILE__) + "/coupler/extensions"
require File.dirname(__FILE__) + "/coupler/base"
