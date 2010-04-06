module Coupler
  class TransformerFactory
    def self.build(resource, &block)
      new(resource, &block).klass
    end

    attr_reader :klass
    def initialize(resource, &block)
      @resource = resource
      @block = block
      setup_class
    end

    def setup_class
      @klass = Class.new(Transformers::Base)
      @klass.send(:class_variable_set, :@@block, @block)
      @klass.class_eval(<<-EOF, __FILE__, __LINE__)
        def transform(record)
          @@block.call
        end
      EOF
    end

    def value
      "foo"
    end
  end
end
