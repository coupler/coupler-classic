require File.join(File.dirname(__FILE__), 'server')

module Coupler
  class Runner
    def initialize
      server = Coupler::Server.instance
      server.start

      begin
        Signal.trap("INT") { server.shutdown }
        require File.expand_path(File.join(File.dirname(__FILE__), "..", 'coupler'))
        Coupler::Base.run!
      ensure
        server.shutdown
      end
    end
  end
end
