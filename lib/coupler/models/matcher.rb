pp caller
module Coupler
  module Models
    class Matcher < Sequel::Model
      include CommonModel
      many_to_one :scenario
      one_to_many :comparisons

      plugin :nested_attributes
      nested_attributes :comparisons, :destroy => true

      def cross_match?
        comparisons.any? { |c| c.cross_match? }
      end

      private
        def validate
          super
          # use comparisons instead of comparisons_dataset, because the
          # comparisons aren't created yet
          result = comparisons.any? do |comparison|
            comparison.lhs_type == "field" && comparison.rhs_type == "field"
          end
          if !result
            errors.add(:base, "At least one field-to-field comparison is required.")
          end
        end

        def after_save
          super
          s = scenario
          s.set_linkage_type
          s.save
        end
    end
  end
end
