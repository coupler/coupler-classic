module Coupler
  module Transformers
    class Base
      def transform(*args)
        raise NotImplementedError
      end
    end
  end
end
