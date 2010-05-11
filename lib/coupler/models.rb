module Coupler
  module Models
    %w{connection project resource field transformer transformation scenario matcher job result comparison}.each do |name|
      autoload(name.capitalize.to_sym, File.dirname(__FILE__) + "/models/#{name}")
    end
  end
end

require File.dirname(__FILE__) + "/models/common_model"
require File.dirname(__FILE__) + "/models/jobify"
