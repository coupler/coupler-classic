module Coupler
  module Models
    class Scenario
      class GroupCounter
        def initialize
          @num = 0
          @mutex = Mutex.new
        end

        def next_group
          @mutex.synchronize { @num += 1 }
        end
      end
    end
  end
end
