module Coupler
  module Comparators
    class Exact < Base
      OPTIONS = [
        {:label => "Field", :name => "field_name", :type => "text"}
      ]

      def initialize(options)
        super

        case options['field_name']
        when String
          @first_field_name = @second_field_name = options['field_name'].to_sym
        when Array
          @first_field_name, @second_field_name = options['field_name'][0..1].collect { |x| x.to_sym }
        else
          raise "invalid options"
        end
      end

      def score(first, second)
        val_1 = first[@first_field_name]
        val_2 = second[@second_field_name]
        if val_1.nil? || val_2.nil? || val_1 != val_2
          0
        else
          100
        end
      end
    end
    self.register("exact", Exact)
  end
end
