require 'rubygems'
require 'sinatra/base'
require 'rack/flash'
require 'erb'
require 'singleton'
require 'delegate'
require 'jdbc/mysql'
require 'sequel'
require 'logger'

module Coupler
  ROOT = File.expand_path(File.join(File.dirname(__FILE__), ".."))
end

COUPLER_ENV = ENV['COUPLER_ENV']

require File.dirname(__FILE__) + "/coupler/server"
require File.dirname(__FILE__) + "/coupler/config"

# FIXME: this is a crappy hack; Sequel doesn't play nicely
if Coupler::Server.instance.is_running?
  # instantiate the connection
  Coupler::Config.instance

  require File.dirname(__FILE__) + "/coupler/models"
  require File.dirname(__FILE__) + "/coupler/transformers"
  require File.dirname(__FILE__) + "/coupler/extensions"
  require File.dirname(__FILE__) + "/coupler/base"
end
