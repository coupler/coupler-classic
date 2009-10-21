module Coupler
  module Models
    class Project < Sequel::Model
      include CommonModel
      one_to_many :resources

      def before_create
        self.slug ||= self.name.downcase.gsub(/\s+/, "-")
      end

      def validate
        errors[:name] << "is required"  if self.name.nil? || self.name == ""

        obj = self.class[:slug => self.slug]
        if self.new?
          errors[:slug] << "is already taken"   if obj
        else
          errors[:slug] << "is already taken"   if obj != self
        end
      end
    end
  end
end
