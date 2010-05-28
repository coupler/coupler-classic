module Coupler
  module Models
    class Matcher < Sequel::Model
      include CommonModel
      many_to_one :scenario
      one_to_many :comparisons

      plugin :nested_attributes
      nested_attributes :comparisons, :destroy => true
    end
  end
end
