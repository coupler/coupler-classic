module Coupler
  module Comparators
    class Base
      def initialize(options)
        @options = options
      end

      def score(first, second)
        raise NotImplementedError
      end
    end
  end
end
