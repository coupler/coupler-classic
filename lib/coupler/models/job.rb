module Coupler
  module Models
    class Job < Sequel::Model
      include CommonModel

      many_to_one :resource
      many_to_one :scenario

      def percent_completed
        total > 0 ? completed * 100 / total : 0
      end
    end
  end
end
