COUPLER_ROOT = File.expand_path(File.join(File.dirname(__FILE__), ".."))
COUPLER_ENV  = ENV['COUPLER_ENV']

# gems/stdlibs
require 'java'
require 'erb'
require 'delegate'
require 'singleton'
require 'logger'
require 'rubygems'
require 'sinatra/base'
require 'rack/flash'
require 'jdbc/mysql'
require 'sequel'

# vendored stuff
require File.join(COUPLER_ROOT, "vendor", 'thread_pool', 'lib', 'thread_pool')
#require File.join(COUPLER_ROOT, "vendor", 'quartz', 'quartz-1.6.6.jar')
#require File.join(COUPLER_ROOT, "vendor", 'quartz', 'lib', 'core', 'commons-logging-1.1.jar')

module Coupler
  @@logger = Logger.new(File.join(COUPLER_ROOT, 'log', 'coupler.log'))
  def self.logger
    @@logger
  end
end

require File.dirname(__FILE__) + "/coupler/server"
require File.dirname(__FILE__) + "/coupler/config"

# FIXME: this is a crappy hack; Sequel doesn't play nicely
if Coupler::Server.instance.is_running?
  # instantiate the connection
  Coupler::Config.instance

  require File.dirname(__FILE__) + "/coupler/models"
  require File.dirname(__FILE__) + "/coupler/transformers"
  require File.dirname(__FILE__) + "/coupler/extensions"

  require File.dirname(__FILE__) + "/coupler/helpers"
  require File.dirname(__FILE__) + "/coupler/base"
end
