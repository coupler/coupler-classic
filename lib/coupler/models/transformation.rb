module Coupler
  module Models
    class Transformation < Sequel::Model
      include CommonModel
      many_to_one :resource
      many_to_one :source_field, :class => Field
      many_to_one :result_field, :class => Field
      many_to_one :transformer

      plugin :nested_attributes
      nested_attributes :result_field
      nested_attributes :transformer, :destroy => false

      def transform(data)
        transformer.transform(data, {
          :in => source_field.name.to_sym,
          :out => result_field.name.to_sym
        })
      end

      def field_changes
        transformer.field_changes(source_field)
      end

      # NOTE: The fact that the aliased name doesn't have an = at the end is
      # important.  Ruby methods with names that have = at the end always
      # return the RHS value, regardless of what the method actually returns.
      # The only way to grab the associated object that gets created from the
      # nested attributes methods is by fetching the return value.
      #
      alias :original_result_field_attributes :result_field_attributes=
      def result_field_attributes=(h)
        @staged_result_field = self.original_result_field_attributes(h.merge({
          :is_generated => 1
        }))
      end

      def deletable?
        position == self.class.max(:position) &&
          (result_field.nil? || !result_field.is_generated || result_field.scenarios_dataset.count == 0)
      end

      private
        def before_validation
          super
          if source_field_id && !result_field_id && !@staged_result_field
            self.result_field_id = source_field_id
          end

          if @staged_result_field && transformer && source_field && resource_id
            hash = transformer.field_changes(source_field).values[0]
            if hash.empty?
              hash.update({
                :type => source_field[:type],
                :db_type => source_field[:db_type]
              })
            end
            hash[:resource_id] = resource_id
            @staged_result_field.set(hash)
          end
        end

        def validate
          super
          validates_presence [:resource_id, :source_field_id]
          if transformer.nil?
            errors.add(:transformer_id, "is not present")
          end
          if errors.empty?
            source_field = resource.fields_dataset[:id => source_field_id]
            if source_field.nil?
              errors.add(:source_field_id, "is invalid")
            else
              if transformer.allowed_types.is_a?(Array) && !transformer.allowed_types.include?(source_field.final_type)
                errors.add(:base, "#{transformer.name} cannot transform type '#{source_field.final_type}'")
              end
            end

            if !@staged_result_field
              result_field = result_field_id ? resource.fields_dataset[:id => result_field_id] : nil
              if result_field.nil?
                errors.add(:result_field_id, "is invalid")
              end
            end
          end
        end

        def before_create
          super
          self.position ||= self.class.filter(:resource_id => resource_id).count + 1
        end

        def after_save
          super
          resource.refresh_fields!
        end

        def before_destroy
          # Prevent all but the last transformation from being destroyed
          #
          # FIXME: This is probably temporary, since I'm putting off
          # programming the complex logic required to enable deletion from the
          # middle of a transformation stack.
          #
          super
          deletable?
        end

        def after_destroy
          super
          if result_field && result_field.is_generated && self.class.filter(:result_field_id => result_field.id).count == 0
            result_field.destroy
          end
          resource.refresh_fields!  if resource
        end
    end
  end
end
