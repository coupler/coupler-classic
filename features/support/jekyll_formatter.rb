require 'cucumber/formatter/html'

module Coupler
  class JekyllFormatter < Cucumber::Formatter::Html
    def initialize(step_mother, io, options)
      io << "---\ntitle: Features\n---\n"
      super(step_mother, io, options)
    end
  end
end
