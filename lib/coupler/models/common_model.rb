module Coupler
  module Models
    module CommonModel
      def self.included(base)
        base.raise_on_save_failure = false
      end

      def before_create
        now = Time.now
        self.created_at = now
        self.updated_at = now
      end

      def before_update
        now = Time.now
        self.updated_at = now
      end

      def save!
        self.class.raise_on_save_failure = true
        begin
          save
        ensure
          self.class.raise_on_save_failure = false
        end
      end
    end
  end
end
