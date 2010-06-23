module Coupler
  module Models
    class Transformation < Sequel::Model
      include CommonModel
      many_to_one :resource
      many_to_one :source_field, :class => Field
      many_to_one :transformer

      def transform(data)
        sym = source_field.name.to_sym
        transformer.transform(data, { :in => sym, :out => sym })
      end

      def field_changes
        transformer.field_changes(source_field)
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
            source_field = resource.fields_dataset[:id => source_field_id]
            if source_field.nil?
              errors[:source_field_id] << "is invalid"
            else
              if !transformer.allowed_types.include?(source_field[:type])
                errors[:base] << "#{transformer.name} cannot transform type '#{source_field[:type]}'"
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
