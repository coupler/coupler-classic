module Coupler
  module Models
    class Matcher < Sequel::Model
      include CommonModel
      many_to_one :scenario
      one_to_many :comparisons

      plugin :nested_attributes
      nested_attributes :comparisons do |hash|
        (hash['field_1_id'].nil? || hash['field_1_id'] == '') &&
          (hash[:field_1_id].nil? || hash[:field_1_id] == '')
      end

      private
        def validate
          if self.comparator_name.nil? || self.comparator_name == ""
            errors[:comparator_name] << "is required"
          elsif Comparators[self.comparator_name].nil?
            errors[:comparator_name] << "is not valid"
          end
        end
    end
  end
end
