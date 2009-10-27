module Coupler
  module Models
    module CommonModel
      def self.included(base)
        base.raise_on_save_failure = false
      end

      def save!
        self.class.raise_on_save_failure = true
        begin
          save
        ensure
          self.class.raise_on_save_failure = true
        end
      end
    end
  end
end
