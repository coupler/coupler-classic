module Coupler
  module Models
    class Field < Sequel::Model
      include CommonModel

      many_to_one :resource
    end
  end
end
