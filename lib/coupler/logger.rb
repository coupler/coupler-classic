module Coupler
  class Logger < Delegator
    include Singleton

    def initialize
      log_path = Coupler.log_path
      Dir.mkdir(log_path)    if !File.exist?(log_path)
      @logger = ::Logger.new(File.join(log_path, "#{Coupler.environment}.log"))
      super(@logger)
    end

    def __getobj__
      @logger
    end
  end
end
