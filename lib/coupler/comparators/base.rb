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

      def initialize(options)
        @options = options
        keys = options['key']
        keys = [keys] if !keys.is_a?(Array)
        @keys = keys.collect { |k| k.to_sym }
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
