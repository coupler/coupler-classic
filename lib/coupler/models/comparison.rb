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
      plugin :serialization, :marshal, :raw_lhs_value, :raw_rhs_value

      def lhs_rhs_value(name)
        case self[:"#{name}_type"]
        when "field"
          Field[:id => send("raw_#{name}_value")]
        else
          send("raw_#{name}_value")
        end
      end
      def lhs_value; lhs_rhs_value("lhs"); end
      def rhs_value; lhs_rhs_value("rhs"); end

      def lhs_rhs_label(name)
        case self[:"#{name}_type"]
        when "field"
          field = lhs_rhs_value(name)
          result = field.name
          resource_name = field.resource.name
          if self[:"#{name}_which"]
            resource_name << %{<span class="sup">#{self[:"#{name}_which"]}</span>}
          end
          result << " (#{resource_name})"
        else
          lhs_rhs_value(name).inspect
        end
      end
      def lhs_label; lhs_rhs_label("lhs"); end
      def rhs_label; lhs_rhs_label("rhs"); end

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
          validates_presence [:raw_lhs_value, :raw_rhs_value]
          validates_includes TYPES, [:lhs_type, :rhs_type]
          validates_includes OPERATORS, :operator
          validates_includes [1, 2], :lhs_which   if lhs_type == 'field'
          validates_includes [1, 2], :rhs_which   if rhs_type == 'field'

          if lhs_type == 'field' && rhs_type == 'field' && (lhs_field = lhs_value) && (rhs_field = rhs_value)
            if lhs_field[:type] != rhs_field[:type]
              errors.add(:base, "Comparing fields of different types is currently disallowed.")
            end
            if lhs_which != rhs_which && operator != 'equals'
              errors.add(:operator, "is invalid; can't compare fields with anything but equals at the moment.")
            end
          end
        end

        def before_save
          self.raw_lhs_value = coerce_value(lhs_type, raw_lhs_value)
          self.raw_rhs_value = coerce_value(rhs_type, raw_rhs_value)
          super
        end
    end
  end
end
