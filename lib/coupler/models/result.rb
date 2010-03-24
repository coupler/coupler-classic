module Coupler
  module Models
    class Result < Sequel::Model
      include CommonModel
      many_to_one :scenario

      private
        def before_save
          super
          self[:scenario_version] = scenario.version
        end
    end
  end
end
