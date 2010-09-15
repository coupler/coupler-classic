module Coupler
  module Models
    class Comparison < Sequel::Model
      include CommonModel

      OPERATORS = {
        "equals" => "=",
        "does_not_equal" => "!=",
        "greater_than" => ">",
        "less_than" => "<",
      }
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

          # FIXME: this should be a view helper, probably
          def #{name}_label
            case #{name}_type
            when "field"
              result = #{name}_value.name
              resource_name = #{name}_value.resource.name
              if #{name}_which
                resource_name << %{<span class="sup">\#{#{name}_which}</span>}
              end
              result << " (\#{resource_name})"
            else
              raw_#{name}_value.inspect
            end
          end
        END
      end

      def fields
        result = []
        result << lhs_value if lhs_type == 'field'
        result << rhs_value if rhs_type == 'field'
        result
      end

      def operator_symbol
        OPERATORS[operator]
      end

      def apply(dataset)
        lhs = lhs_type == 'field' ? lhs_value.name.to_sym : lhs_value
        rhs = rhs_type == 'field' ? rhs_value.name.to_sym : rhs_value
        filters = []
        if lhs_type == 'field' && rhs_type == 'field' && lhs_which != rhs_which
          opts = dataset.opts
          select = opts[:select] || []
          order  = opts[:order] || []

          (lhs == rhs ? [lhs] : [lhs, rhs]).each do |field|
            # NOTE: This assumes that the presence of a field name in the select array implies
            # that the filters for it are already in place.  I don't want to go searching through
            # Sequel's filter expressions to find out what's in there.
            if !select.include?(field)
              select.push(field)
              order.push(field)
              filters.push(~{field => nil})
            end
          end
          dataset = dataset.clone(:select => select, :order => order)
        else
          filters << Sequel::SQL::BooleanExpression.new(operator_symbol.to_sym, lhs, rhs)
        end
        dataset.filter(*filters)
      end

      def blocking?
        lhs_type != 'field' || rhs_type != 'field' || lhs_which == rhs_which || operator != 'equals'
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

        def before_validation
          super
          self.lhs_which ||= 1  if lhs_type == 'field'
          self.rhs_which ||= 2  if rhs_type == 'field'
        end

        def validate
          super
          %w{lhs rhs}.each do |name|
            attr = :"#{name}_value"
            value = send("raw_#{name}_value")
            if value.nil? || value == ''
              errors.add(attr, "is required")
            end
          end
          validates_includes TYPES, [:lhs_type, :rhs_type]
          validates_includes OPERATORS, :operator
          validates_includes [1, 2], :lhs_which   if lhs_type == 'field'
          validates_includes [1, 2], :rhs_which   if rhs_type == 'field'
        end

        def before_save
          self.lhs_value = coerce_value(lhs_type, raw_lhs_value)
          self.rhs_value = coerce_value(rhs_type, raw_rhs_value)
          super
        end
    end
  end
end
