# java integration
require 'java'
require 'jruby/core_ext'

# gems/stdlibs
require 'erb'
require 'delegate'
require 'singleton'
require 'sinatra/base'
require 'rack/flash'
require 'sequel'
require 'json'
require 'fastercsv'

# vendored stuff
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'vendor', 'ruby', 'thread_pool', 'lib')) # this won't hurt anything if we're inside a jar
require 'thread_pool'
begin
  org.quartz.Job
rescue NameError
  Coupler::Config.require_vendor_libs('quartz')
end

# coupler libs
require File.dirname(__FILE__) + "/coupler/config"
require File.dirname(__FILE__) + "/coupler/logger"
require File.dirname(__FILE__) + "/coupler/database"
require File.dirname(__FILE__) + "/coupler/scheduler"
require File.dirname(__FILE__) + "/coupler/models"
require File.dirname(__FILE__) + "/coupler/transformers"
require File.dirname(__FILE__) + "/coupler/transformer_factory"
require File.dirname(__FILE__) + "/coupler/comparators"
require File.dirname(__FILE__) + "/coupler/jobs"
require File.dirname(__FILE__) + "/coupler/score_set"
require File.dirname(__FILE__) + "/coupler/extensions"
require File.dirname(__FILE__) + "/coupler/helpers"
require File.dirname(__FILE__) + "/coupler/base"
