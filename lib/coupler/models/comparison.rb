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

      def apply(dataset, which = nil)
        lhs = lhs_type == 'field' ? lhs_value.name.to_sym : lhs_value
        rhs = rhs_type == 'field' ? rhs_value.name.to_sym : rhs_value
        if !blocking?
          filters = []
          tmp = dataset.opts
          opts = {
            :select => tmp[:select] ? tmp[:select].dup : [],
            :order  => tmp[:order]  ? tmp[:order].dup  : []
          }

          fields =
            case which
            when nil then lhs == rhs ? [lhs] : [lhs, rhs]
            when 0   then [lhs]
            when 1   then [rhs]
            end
          fields.each_with_index do |field, i|
            index = i == 0 ? 0 : -1

            # NOTE: This assumes that the presence of a field name in the
            # select array implies that the filters for it are already in
            # place.  I don't want to go searching through Sequel's filter
            # expressions to find out what's in there.
            if !opts[:select].include?(field)
              opts[:select].push(field)
              opts[:order].push(field)
              opts[:modified] = true
              filters.push(~{field => nil})
            end
          end
          if opts.delete(:modified)
            dataset = dataset.clone(opts).filter(*filters)
          end
        else
          # Figure out which side to apply this comparison to.
          tmp_which = nil
          if !which.nil?
            if lhs_type == 'field' && rhs_type == 'field'
              if lhs_which == rhs_which
                tmp_which = lhs_which == 1 ? 0 : 1
              else
                raise "unsupported" # FIXME
              end
            elsif lhs_type == 'field'
              tmp_which = lhs_which == 1 ? 0 : 1
            elsif rhs_type == 'field'
              tmp_which = rhs_which == 1 ? 0 : 1
            else
              # Doesn't matter.  Apply to either side.
            end
          end

          if which.nil? || tmp_which.nil? || which == tmp_which
            expr = Sequel::SQL::BooleanExpression.new(operator_symbol.to_sym, lhs, rhs)
            dataset = dataset.filter(expr)
          end
        end
        dataset
      end

      def blocking?
        lhs_type != 'field' || rhs_type != 'field' || lhs_which == rhs_which || operator != 'equals'
      end

      def cross_match?
        lhs_type == 'field' && rhs_type == 'field' && lhs_which != rhs_which && lhs_value.id != rhs_value.id && lhs_value.resource_id == rhs_value.resource_id
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
