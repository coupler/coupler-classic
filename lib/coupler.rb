require 'java'
require 'jruby/core_ext'

require 'rbconfig'
require 'fileutils'
require 'erb'
require 'delegate'
require 'singleton'
require 'logger'
require 'optparse'
require 'thwait'
require 'digest'
require 'rack'
require 'rack/mime'   # This is an attempt to avoid NameError exceptions
require 'sinatra/base'
require 'rack/flash'
require 'sequel'
require 'sequel/extensions/migration'
require 'json'
require 'fastercsv'
require 'carrierwave'
require 'mongrel'
#require 'jdbc/mysql'  # Sequel should load this when it needs to.
#require 'jdbc/h2'     # Sequel should load this when it needs to.

require File.dirname(__FILE__) + "/coupler/logger"
require File.dirname(__FILE__) + "/coupler/database"
require File.dirname(__FILE__) + "/coupler/scheduler"
require File.dirname(__FILE__) + "/coupler/data_uploader"
require File.dirname(__FILE__) + "/coupler/import_buffer"
require File.dirname(__FILE__) + "/coupler/models"
require File.dirname(__FILE__) + "/coupler/extensions"
require File.dirname(__FILE__) + "/coupler/helpers"
require File.dirname(__FILE__) + "/coupler/runner"
require File.dirname(__FILE__) + "/coupler/base"
