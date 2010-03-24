module Coupler
  module Models
    module CommonModel
      @@versioned = {}

      def self.included(base)
        base.raise_on_save_failure = false

        # decide whether or not to version this model
        versions_table_name = "#{base.table_name}_versions".to_sym
        if base.db.tables.include?(versions_table_name)
          @@versioned[base] = versions_table_name
        end
      end

      def before_create
        super
        now = Time.now
        self[:created_at] = now
        self[:updated_at] = now
      end

      def before_update
        super
        now = Time.now
        self[:updated_at] = now
      end

      def before_save
        super
        if @@versioned[self.class]
          self[:version] = self[:version].nil? ? 1 : self[:version] + 1
        end
      end

      def after_save
        super
        if versions_table_name = @@versioned[self.class]
          dataset = self.db[versions_table_name]
          hash = self.values.clone
          hash[:current_id] = hash.delete(:id)
          dataset.insert(hash)
        end
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
