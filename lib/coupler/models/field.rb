module Coupler
  module Models
    class Field < Sequel::Model
      include CommonModel
      many_to_one :resource
      one_to_many :transformations

      def original_column_options
        { :name => name, :type => db_type, :primary_key => is_primary_key }
      end

      def local_column_options
        { :name => name, :type => local_db_type || db_type,
          :primary_key => is_primary_key }
      end

      private
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
