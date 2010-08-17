module Coupler
  module Models
    class Field < Sequel::Model
      include CommonModel
      many_to_one :resource
      one_to_many :transformations, :key => :source_field_id

      def original_column_options
        { :name => name, :type => db_type, :primary_key => is_primary_key }
      end

      def local_column_options
        { :name => name, :type => final_db_type,
          :primary_key => is_primary_key }
      end

      def final_type
        local_type || self[:type]
      end

      def final_db_type
        local_db_type || db_type
      end

      private
        def validate
          super
          validates_presence [:name, :resource_id]
          validates_unique [:name, :resource_id]
        end

        def before_save
          super
          case is_primary_key
          when TrueClass, 1
            self.is_selected = 1
          end
        end
    end
  end
end
