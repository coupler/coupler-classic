module Coupler
  module Models
    class Matcher < Sequel::Model
      include CommonModel
      plugin :serialization, :marshal, :comparator_options
      many_to_one :scenario

      private
        def validate
          if self.comparator_name.nil? || self.comparator_name == ""
            errors[:comparator_name] << "is required"
          elsif Comparators[self.comparator_name].nil?
            errors[:comparator_name] << "is not valid"
          end
        end

        def after_validation
          # This is a workaround; Marshal.dump chokes on Sinatra's params
          # hash for some reason
          opts = self.comparator_options
          if opts.is_a?(Hash)
            self.comparator_options = {}
            opts.each_pair do |key, value|
              self.comparator_options[key] = value
            end
          end
        end
    end
  end
end
