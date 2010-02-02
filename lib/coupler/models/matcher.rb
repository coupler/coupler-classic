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
          self.comparator_options = fix_hash(self.comparator_options)
        end

        def fix_hash(hash)
          retval = {}
          hash.each_pair do |key, value|
            retval[key] = value.is_a?(Hash) ? fix_hash(value) : value
          end
          retval
        end
    end
  end
end
