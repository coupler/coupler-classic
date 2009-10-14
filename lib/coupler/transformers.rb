module Coupler
  module Transformers
    @@list = {}
    def self.list
      @@list
    end

    def self.register(name, klass)
      @@list[name] = klass
    end
  end
end

require File.dirname(__FILE__) + "/transformers/base"
require File.dirname(__FILE__) + "/transformers/downcase"
