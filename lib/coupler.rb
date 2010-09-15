# java integration
require 'java'
require 'jruby/core_ext'

# gems/stdlibs
require 'erb'
require 'delegate'
require 'singleton'
require 'logger'
require 'optparse'
require 'thwait'
require 'rack'
require 'rack/mime'   # This is an attempt to avoid NameError exceptions
require 'sinatra/base'
require 'rack/flash'
require 'sequel'
require 'sequel/extensions/migration'
require 'json'
require 'fastercsv'
require 'carrierwave'

require File.dirname(__FILE__) + "/coupler/config"

# vendored stuff

# mysql embedded
begin
  com.mysql.management.MysqldResource
rescue NameError
  # load jar files only if necessary
  Coupler::Config.require_vendor_libs('mysql-connector-mxj')
end

# jdbc/mysql
begin
  com.mysql.jdbc.Driver
rescue NameError
  Coupler::Config.require_vendor_libs('mysql-connector-java')
end

# coupler libs
require File.dirname(__FILE__) + "/coupler/logger"
require File.dirname(__FILE__) + "/coupler/server"
require File.dirname(__FILE__) + "/coupler/database"
require File.dirname(__FILE__) + "/coupler/scheduler"
require File.dirname(__FILE__) + "/coupler/data_uploader"
require File.dirname(__FILE__) + "/coupler/row_buffer"
require File.dirname(__FILE__) + "/coupler/models"
require File.dirname(__FILE__) + "/coupler/score_set"
require File.dirname(__FILE__) + "/coupler/extensions"
require File.dirname(__FILE__) + "/coupler/helpers"
require File.dirname(__FILE__) + "/coupler/runner"
require File.dirname(__FILE__) + "/coupler/base"
