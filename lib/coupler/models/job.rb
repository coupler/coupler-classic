module Coupler
  module Models
    class Job < Sequel::Model
      include CommonModel

      many_to_one :resource
      many_to_one :scenario
    end
  end
end
