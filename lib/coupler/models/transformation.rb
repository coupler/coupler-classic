module Coupler
  module Models
    class Transformation < Sequel::Model
      include CommonModel
      many_to_one :resource
      many_to_one :transformer

      def transform(data)
        sym = field_name.to_sym
        transformer.transform(data, { :in => sym, :out => sym })
      end

      def new_schema(schema)
        transformer.new_schema(schema, field_name)
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
            field_info = resource.source_schema.assoc(field_name.to_sym)
            if field_info.nil?
              errors[:field_name] << "is invalid"
            else
              field_type = field_info[1][:type].to_s
              if !transformer.allowed_types.include?(field_type)
                errors[:base] << "#{transformer.name} cannot transform type '#{field_type}'"
              end
            end
          end
        end
    end
  end
end
