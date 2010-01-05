module Coupler
  module Models
    class Scenario < Sequel::Model
      include CommonModel
      many_to_one :project
      many_to_many :resources
      one_to_many :matchers

      private
        def validate
          if self.name.nil? || self.name == ""
            errors[:name] << "is required"
          else
            obj = self.class[:name => name]
            if self.new?
              errors[:name] << "is already taken"   if obj
            else
              errors[:name] << "is already taken"   if obj.id != self.id
            end
          end
        end
    end
  end
end
