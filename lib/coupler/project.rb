module Coupler
  class Project < Sequel::Model
    one_to_many :resources
    self.raise_on_save_failure = false

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
