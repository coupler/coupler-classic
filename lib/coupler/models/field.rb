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
        { :name => name, :type => local_db_type || db_type,
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

          # require unique name across resources
          ary = [{:name => name, :resource_id => resource_id}]
          ary << ~{:id => id}   if !new?
          if self.class.filter(*ary).count > 0
            errors[:name] << "is already taken"
          end
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
