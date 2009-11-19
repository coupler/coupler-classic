module Coupler
  module Transformers
    class Base
      def initialize(options)
        @options = options
        @field_name = options[:field_name] ? options[:field_name].to_sym : nil
      end

      def transform(*args)
        raise NotImplementedError
      end

      def schema(original_schema)
        original_schema
      end
    end
  end
end
