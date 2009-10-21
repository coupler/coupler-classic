require 'rubygems'
require 'sinatra/base'
require 'rack/flash'
require 'erb'
require 'singleton'
require 'delegate'
require 'jdbc/mysql'
require 'sequel'

module Coupler
  ROOT = File.expand_path(File.join(File.dirname(__FILE__), ".."))
end

COUPLER_ENV = ENV['COUPLER_ENV']

require File.dirname(__FILE__) + "/coupler/server"
require File.dirname(__FILE__) + "/coupler/config"

require File.dirname(__FILE__) + "/coupler/models"
require File.dirname(__FILE__) + "/coupler/transformers"
require File.dirname(__FILE__) + "/coupler/extensions"
require File.dirname(__FILE__) + "/coupler/base"
