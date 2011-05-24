module Coupler
  module Models
    # NOTE: using autoload here would undoubtedly be more efficient, but
    # I need to make sure the database connection is instantiated before
    # loading these classes because of how Sequel::Model works.
    #%w{connection project resource field transformer transformation scenario matcher job result comparison}.each do |name|
      #autoload(name.capitalize.to_sym, File.dirname(__FILE__) + "/models/#{name}")
    #end

    NAMES = [
      :Connection, :Project, :Resource, :Field, :Transformer,
      :Transformation, :Scenario, :Matcher, :Job, :Result, :Comparison,
      :Import
    ]

    def self.load_all
      Database.instance
      NAMES.each do |name|
        require File.dirname(__FILE__) + "/models/#{name.to_s.downcase}"
      end
    end

    def self.const_missing(name)
      name = name.to_sym
      if NAMES.include?(name)
        Database.instance
        require File.dirname(__FILE__) + "/models/#{name.to_s.downcase}"
        const_get(name)
      else
        puts "#{name.inspect} wasn't in #{NAMES.inspect}"
        super
      end
    end
  end
end

require File.dirname(__FILE__) + "/models/common_model"
require File.dirname(__FILE__) + "/models/jobify"
