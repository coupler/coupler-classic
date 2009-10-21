module Coupler
  module Models
    class Transformation < Sequel::Model
      include CommonModel
      many_to_one :resource
    end
  end
end
