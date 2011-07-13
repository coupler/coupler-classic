if !defined?(Coupler::Database)
  raise "Database isn't initialized yet!"
end

module Coupler
  module Models
  end
end

require File.dirname(__FILE__) + "/models/common_model"
require File.dirname(__FILE__) + "/models/jobify"
require File.dirname(__FILE__) + "/models/comparison"
require File.dirname(__FILE__) + "/models/connection"
require File.dirname(__FILE__) + "/models/field"
require File.dirname(__FILE__) + "/models/import"
require File.dirname(__FILE__) + "/models/job"
require File.dirname(__FILE__) + "/models/matcher"
require File.dirname(__FILE__) + "/models/project"
require File.dirname(__FILE__) + "/models/resource"
require File.dirname(__FILE__) + "/models/result"
require File.dirname(__FILE__) + "/models/scenario"
require File.dirname(__FILE__) + "/models/transformation"
require File.dirname(__FILE__) + "/models/transformer"
