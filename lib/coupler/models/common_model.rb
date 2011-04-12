module Coupler
  module Models
    module CommonModel
      module ClassMethods
        def recently_accessed
          col = columns.include?(:last_accessed_at) ? :last_accessed_at : :updated_at
          order(col.desc).limit(3).all
        end

        def as_of_version(id, version)
          versions_dataset[:current_id => id, :version => version]
        end

        def as_of_time(id, time)
          versions_dataset.filter(["current_id = ? AND updated_at <= ?", id, time]).first
        end

        def versions_table_name
          "#{table_name}_versions".to_sym
        end

        def versions_dataset
          db[versions_table_name]
        end

        def const_missing(name)
          Models.const_missing(name)
        end
      end

      @@versioned = {}
      def self.included(base)
        base.extend(ClassMethods)
        base.raise_on_save_failure = false
        base.plugin :validation_helpers

        # decide whether or not to version this model
        versions_table_name = base.versions_table_name
        if base.db.tables.include?(versions_table_name)
          @@versioned[base] = versions_table_name
          base.send(:attr_accessor, :delete_versions_on_destroy)
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
        if @@versioned[self.class] && !@skip_new_version
          self[:version] = self[:version].nil? ? 1 : self[:version] + 1
        end
      end

      def after_save
        super
        if @skip_new_version
          @skip_new_version = nil
        else
          if versions_table_name = @@versioned[self.class]
            dataset = self.db[versions_table_name]
            hash = self.values.clone
            hash[:current_id] = hash.delete(:id)
            dataset.insert(hash)
          end
        end
      end

      def after_destroy
        super
        if @delete_versions_on_destroy && (versions_table_name = @@versioned[self.class])
          dataset = self.db[versions_table_name]
          dataset.filter(:current_id => id).delete
        end
      end

      def save!(*args)
        if !save(*args)
          raise "couldn't save: " + errors.full_messages.join("; ")
        end
        self
      end

      def touch!
        @skip_new_version = true
        update(:last_accessed_at => Time.now)
      end
    end
  end
end
