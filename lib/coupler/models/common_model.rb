module Coupler
  module Models
    module CommonModel
      def self.included(base)
        base.raise_on_save_failure = false
      end
    end
  end
end
