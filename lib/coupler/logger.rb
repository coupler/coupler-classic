require 'logger'

module Coupler
  class Logger < Delegator
    include Singleton

    def initialize
      @logger = ::Logger.new(File.join(File.dirname(__FILE__), "..", "..", "log", "coupler.log"))
    end

    def __getobj__
      @logger
    end
  end
end
