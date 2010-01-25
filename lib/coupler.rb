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

# vendored stuff
vendor_dir = File.join(File.dirname(__FILE__), "..", "vendor")
require File.join(vendor_dir, 'thread_pool', 'lib', 'thread_pool')
require File.join(vendor_dir, 'quartz', 'quartz-1.6.6.jar')
require File.join(vendor_dir, 'quartz', 'lib', 'core', 'commons-logging-1.1.jar')

# coupler libs
require File.dirname(__FILE__) + "/coupler/config"
require File.dirname(__FILE__) + "/coupler/logger"
require File.dirname(__FILE__) + "/coupler/database"
require File.dirname(__FILE__) + "/coupler/scheduler"
require File.dirname(__FILE__) + "/coupler/models"
require File.dirname(__FILE__) + "/coupler/transformers"
require File.dirname(__FILE__) + "/coupler/comparators"
require File.dirname(__FILE__) + "/coupler/jobs"
require File.dirname(__FILE__) + "/coupler/score_set"
require File.dirname(__FILE__) + "/coupler/extensions"
require File.dirname(__FILE__) + "/coupler/helpers"
require File.dirname(__FILE__) + "/coupler/base"
