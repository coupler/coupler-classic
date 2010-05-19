module Coupler
  class Logger < Delegator
    include Singleton

    def initialize
      log_path = File.join(Config.get(:data_path), "log")
      Dir.mkdir(log_path)    if !File.exist?(log_path)
      @logger = ::Logger.new(File.join(log_path, 'coupler.log'))
    end

    def __getobj__
      @logger
    end
  end
end
