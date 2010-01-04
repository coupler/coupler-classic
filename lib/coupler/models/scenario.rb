module Coupler
  module Models
    class Scenario < Sequel::Model
      include CommonModel
      many_to_one :project
      many_to_many :resources
      one_to_many :matchers
    end
  end
end
