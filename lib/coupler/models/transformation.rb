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

        def after_save
          super
          self.resource.update_status!  if self.resource
        end

        def after_destroy
          super
          self.resource.update_status!  if self.resource
        end
    end
  end
end
