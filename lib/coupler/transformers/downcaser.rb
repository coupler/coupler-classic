module Coupler
  module Transformers
    class Downcaser < Base
      def transform(record)
        record[@field_name] = record[@field_name].downcase
        record
      end
    end
    self.register(:downcaser, Downcaser)
  end
end

