module Coupler
  class Resource < Sequel::Model
    many_to_one :project
    self.raise_on_save_failure = false

    def validate
      if self.name.nil? || self.name == ""
        errors[:name] << "is required"
      else
        obj = self.class[:name => name]
        if self.new?
          errors[:name] << "is already taken"   if obj
        end
      end
    end
  end
end
