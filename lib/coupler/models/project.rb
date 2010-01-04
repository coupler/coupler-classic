module Coupler
  module Models
    class Project < Sequel::Model
      include CommonModel
      one_to_many :resources
      one_to_many :scenarios

      private
        def validate
          errors[:name] << "is required"  if self.name.nil? || self.name == ""

          obj = self.class[:slug => self.slug]
          if self.new?
            errors[:slug] << "is already taken"   if obj
          else
            errors[:slug] << "is already taken"   if obj.id != self.id
          end
        end

        def before_save
          super
          self.slug ||= self.name.downcase.gsub(/\s+/, "_")
        end
    end
  end
end
