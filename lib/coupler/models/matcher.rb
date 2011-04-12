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
          if comparisons_dataset.filter(:lhs_type => "field", :rhs_type => "field").count == 0
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
