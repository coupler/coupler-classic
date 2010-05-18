module Coupler
  module Models
    class Comparison < Sequel::Model
      include CommonModel

      many_to_one :matcher
      many_to_one :field_1, :class => 'Coupler::Models::Field'
      many_to_one :field_2, :class => 'Coupler::Models::Field'
    end
  end
end
