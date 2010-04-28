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
        keys = options['key']
        keys = [keys] if !keys.is_a?(Array)
        @keys = keys.collect { |k| k.to_sym }

        @field_names = case options['field_name']
                       when String
                         [options['field_name'].to_sym]
                       when Array
                         options['field_name'].collect { |x| x.to_sym }
                       end
        raise "invalid options"   if @field_names.nil?
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
