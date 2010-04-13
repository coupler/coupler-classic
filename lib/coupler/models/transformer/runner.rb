module Coupler
  module Models
    class Transformer
      class Runner
        instance_methods.each do |m|
          undef_method m unless m =~ /^__|^instance_eval$/
        end

        def initialize(code, input)
          @input = input
          @code = code
        end

        def run
          instance_eval(@code, __FILE__, __LINE__)
        end

        def value
          @input
        end

        def method_missing(name)
          raise NoMethodError
        end
      end
    end
  end
end
