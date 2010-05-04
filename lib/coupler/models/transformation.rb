module Coupler
  module Models
    class Transformation < Sequel::Model
      include CommonModel
      many_to_one :resource
      many_to_one :field
      many_to_one :transformer

      def transform(data)
        sym = field.name.to_sym
        transformer.transform(data, { :in => sym, :out => sym })
      end

      def field_changes
        transformer.field_changes(field)
      end

      private
        def validate
          if resource_id.nil?
            errors[:resource_id] << "is required"
          end

          if transformer_id.nil?
            errors[:transformer_id] << "is required"
          end

          if resource && transformer
            field = resource.fields_dataset[:id => field_id]
            if field.nil?
              errors[:field_id] << "is invalid"
            else
              if !transformer.allowed_types.include?(field[:type])
                errors[:base] << "#{transformer.name} cannot transform type '#{field[:type]}'"
              end
            end
          end
        end

        def after_save
          super
          resource.update_fields
        end
    end
  end
end
