module Coupler
  module Models
    autoload :Comparison,     File.dirname(__FILE__) + "/models/comparison"
    autoload :Connection,     File.dirname(__FILE__) + "/models/connection"
    autoload :Field,          File.dirname(__FILE__) + "/models/field"
    autoload :Import,         File.dirname(__FILE__) + "/models/import"
    autoload :Job,            File.dirname(__FILE__) + "/models/job"
    autoload :Matcher,        File.dirname(__FILE__) + "/models/matcher"
    autoload :Project,        File.dirname(__FILE__) + "/models/project"
    autoload :Resource,       File.dirname(__FILE__) + "/models/resource"
    autoload :Result,         File.dirname(__FILE__) + "/models/result"
    autoload :Scenario,       File.dirname(__FILE__) + "/models/scenario"
    autoload :Transformation, File.dirname(__FILE__) + "/models/transformation"
    autoload :Transformer,    File.dirname(__FILE__) + "/models/transformer"
    autoload :Notification,   File.dirname(__FILE__) + "/models/notification"
  end
end

require File.dirname(__FILE__) + "/models/common_model"
require File.dirname(__FILE__) + "/models/jobify"
