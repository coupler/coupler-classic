require 'pp'
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
require 'carrierwave/sequel'
require 'mongrel'
#require 'jdbc/mysql'  # Sequel should load this when it needs to.
#require 'jdbc/h2'     # Sequel should load this when it needs to.

module Coupler
  def self.environment
    @environment ||= ENV['COUPLER_ENV'] || :production
  end

  def self.db_path(dbname)
    File.join(data_path, 'db', environment.to_s, dbname)
  end

  def self.connection_string(dbname)
    "jdbc:h2:#{db_path(dbname)};IGNORECASE=TRUE"
  end

  def self.upload_path
    @upload_path ||= File.join(data_path, 'uploads', environment.to_s)
  end

  def self.log_path
    @log_path ||= File.join(data_path, 'log')
  end

  def self.data_path
    # NOTE: Unfortunately, this code is in two places. Coupler can
    # be run with or without the launcher, and the launcher needs
    # to know about Coupler's data path before it runs Coupler.
    if !defined? @data_path
      dir =
        if ENV['COUPLER_HOME']
          ENV['COUPLER_HOME']
        else
          case Config::CONFIG['host_os']
          when /mswin|windows/i
            # Windows
            File.join(ENV['APPDATA'], "coupler")
          else
            if ENV['HOME']
              File.join(ENV['HOME'], ".coupler")
            else
              raise "Can't figure out where Coupler lives! Try setting the COUPLER_HOME environment variable"
            end
          end
        end
      if !File.exist?(dir)
        begin
          Dir.mkdir(dir)
        rescue SystemCallError
          raise "Can't create Coupler directory (#{dir})! Is the parent directory accessible?"
        end
      end
      if !File.writable?(dir)
        raise "Coupler directory (#{dir}) is not writable!"
      end
      @data_path = File.expand_path(dir)
    end
    @data_path
  end
end

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
