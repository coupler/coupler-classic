module Coupler
  module Models
    class Comparison < Sequel::Model
      include CommonModel

      OPERATORS = %w{equals}
      TYPES = %w{field integer string}

      many_to_one :matcher
      plugin :serialization, :marshal, :lhs_value, :rhs_value

      %w{lhs rhs}.each do |name|
        class_eval(<<-END, __FILE__, __LINE__)
          alias :raw_#{name}_value :#{name}_value
          def #{name}_value
            case #{name}_type
            when "field"
              Field[:id => raw_#{name}_value]
            else
              raw_#{name}_value
            end
          end
        END
      end

      def fields
        result = []
        result << lhs_value if lhs_type == 'field'
        if rhs_type == 'field'
          result << rhs_value if result.empty? || raw_rhs_value != raw_lhs_value
        end
        result
      end

      private
        def coerce_value(type, value)
          case type
          when "field", "integer"
            value.to_i
          else
            value
          end
        end

        def validate
          super
          %w{lhs rhs}.each do |name|
            attr = :"#{name}_value"
            value = send("raw_#{name}_value")
            if value.nil? || value == ''
              errors.add(attr, "is required")
            end

            attr = :"#{name}_type"
            value = send(attr)
            if !TYPES.include?(value)
              errors.add(attr, "is not valid")
            end
          end
          if !OPERATORS.include?(operator)
            errors.add(:operator, "is not valid")
          end
        end

        def before_save
          self.lhs_value = coerce_value(lhs_type, raw_lhs_value)
          self.rhs_value = coerce_value(rhs_type, raw_rhs_value)
          super
        end
    end
  end
end
