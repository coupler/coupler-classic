module Coupler
  module Comparators
    class Base
      def initialize()
      end

      def compare(*args)
        raise NotImplementedError
      end
    end
  end
end
