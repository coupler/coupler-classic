module Coupler
  module Comparators
    class Base
      def self.scoring_method
        if self.instance_methods(false).include?("score")
          :score
        elsif self.instance_methods(false).include?("simple_score")
          :simple_score
        end
      end

      def self.field_arity
        1
      end

      def initialize(options)
        @options = options
        @keys = options['keys'].collect { |k| k.to_sym }

        @field_names = options['field_names']
        raise "invalid options"   if @field_names.nil?

        case arity = self.class.field_arity
        when :infinite
        else
          raise "wrong arity" if @field_names.length != arity
        end
      end

      def simple_score(first, second)
        raise NotImplementedError
      end

      def score(score_set, *datasets)
        raise NotImplementedError
      end
    end
  end
end
