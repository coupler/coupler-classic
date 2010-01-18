COUPLER_ROOT = File.expand_path(File.join(File.dirname(__FILE__), ".."))
COUPLER_ENV  = ENV['COUPLER_ENV']

# java integration
require 'java'
require 'jruby/core_ext'

# gems/stdlibs
require 'erb'
require 'delegate'
require 'singleton'
require 'logger'
require 'rubygems'
require 'sinatra/base'
require 'rack/flash'
require 'jdbc/mysql'
require 'sequel'
require 'json'

# vendored stuff
vendor_dir = File.join(COUPLER_ROOT, "vendor")
require File.join(vendor_dir, "mysql-connector-mxj-gpl-5-0-9", "mysql-connector-mxj-gpl-5-0-9.jar")
require File.join(vendor_dir, "mysql-connector-mxj-gpl-5-0-9", "mysql-connector-mxj-gpl-5-0-9-db-files.jar")
require File.join(vendor_dir, "mysql-connector-mxj-gpl-5-0-9", "lib", "aspectjrt.jar")
require File.join(vendor_dir, 'thread_pool', 'lib', 'thread_pool')
require File.join(vendor_dir, 'quartz', 'quartz-1.6.6.jar')
require File.join(vendor_dir, 'quartz', 'lib', 'core', 'commons-logging-1.1.jar')

module Coupler
  @@logger = Logger.new(File.join(COUPLER_ROOT, 'log', 'coupler.log'))
  def self.logger
    @@logger
  end
end

require File.dirname(__FILE__) + "/coupler/server"
require File.dirname(__FILE__) + "/coupler/config"
require File.dirname(__FILE__) + "/coupler/scheduler"

# FIXME: this is a crappy hack; Sequel doesn't play nicely
if Coupler::Server.instance.is_running?
  # instantiate the connection
  Coupler::Config.instance

  require File.dirname(__FILE__) + "/coupler/models"
  require File.dirname(__FILE__) + "/coupler/transformers"
  require File.dirname(__FILE__) + "/coupler/comparators"
  require File.dirname(__FILE__) + "/coupler/jobs"
  require File.dirname(__FILE__) + "/coupler/score_set"
  require File.dirname(__FILE__) + "/coupler/extensions"
  require File.dirname(__FILE__) + "/coupler/helpers"
  require File.dirname(__FILE__) + "/coupler/base"
end
