module Coupler
  module Comparators
    class Base
      def initialize
      end

      def score(*args)
        raise NotImplementedError
      end
    end
  end
end
