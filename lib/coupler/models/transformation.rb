module Coupler
  module Models
    class Transformation < Sequel::Model
      include CommonModel
      many_to_one :resource

      private
        def validate
          if self.resource_id.nil?
            errors[:name] << "is required"
          end
        end
    end
  end
end
