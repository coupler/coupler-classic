module Coupler
  module Comparators
    class Exact < Base
      OPTIONS = [
        {:label => "Field", :name => "field_name", :type => "text"}
      ]

      def initialize(options)
        super
        @field_name = options['field_name'] ? options['field_name'].to_sym : nil
      end

      def score(first, second)
        first[@field_name] == second[@field_name] ? 100 : 0
      end
    end
    self.register("exact", Exact)
  end
end
