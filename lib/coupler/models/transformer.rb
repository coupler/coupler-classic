module Coupler
  module Models
    class Transformer < Sequel::Model
      include CommonModel

      plugin :serialization, :marshal, :allowed_types

      TYPES = %w{string integer datetime}
      EXAMPLES = {
        'string'   => 'Test',
        'integer'  => 123,
        'datetime' => lambda { Time.now }
      }

      def transform(data, options)
        input = data[options[:in]]
        runner = Runner.new(code, input)
        output = runner.run
        data[options[:out]] = output
        data
      end

      def preview
        return nil  if allowed_types.nil? || code.nil? || code == ""

        result = {'success' => true}
        examples = EXAMPLES.reject { |k, v| !allowed_types.include?(k) }
        examples.each_pair do |type, obj|
          obj = obj.call  if obj.is_a?(Proc)
          result[type] = { :in => obj }
          begin
            transform(result[type], {:in => :in, :out => :out})

            expected_type = result_type == 'same' ? type : result_type
            actual_type = case result[type][:out]
                          when String then "string"
                          when Fixnum then "integer"
                          when Time, Date, DateTime then "datetime"
                          when NilClass then "null"
                          end

            if actual_type != "null" && expected_type != actual_type
              raise TypeError, "expected #{expected_type}, got #{actual_type}"
            end

          rescue Exception => e
            result[type][:out] = e
            result['success'] = false
          end
        end
        result
      end

      def field_changes(*fields)
        fields.inject({}) do |result, field|
          result[field.id] = hash = {}
          if result_type != 'same'
            hash[:type] = result_type.to_sym

            # TODO: don't hardcode this
            hash[:db_type] = case result_type
                             when 'integer'  then 'int(11)'
                             when 'string'   then 'varchar(255)'
                             when 'datetime' then 'datetime'
                             end
          end
          result
        end
      end

      private
        def validate
          if name.nil? || name == ""
            errors[:name] << "is required"
          else
            if new?
              count = self.class.filter(:name => name).count
              errors[:name] << "is already taken"   if count > 0
            else
              count = self.class.filter(["name = ? AND id != ?", name, id]).count
              errors[:name] << "is already taken"   if count > 0
            end
          end

          if allowed_types.nil? || allowed_types.empty?
            errors[:allowed_types] << "cannot be empty"
          else
            bad = (allowed_types - TYPES).uniq
            errors[:allowed_types] << "has invalid type(s): #{bad.join(', ')}"   if !bad.empty?
          end

          if result_type.nil? || result_type == ""
            errors[:result_type] << "is required"
          elsif !TYPES.include?(result_type) && result_type != "same"
            errors[:result_type] << "is invalid"
          end

          if code.nil? || code == ""
            errors[:code] << "is required"
          else
            io = java.io.ByteArrayInputStream.new(code.to_java_bytes)
            begin
              JRuby.runtime.parseInline(io, "line", nil)
            rescue Exception => e
              errors[:code] << "has errors: #{e.to_s}"
            end
          end

          if errors.empty?
            result = preview
            if !(result && result['success'])
              errors[:code] << "has errors"
            end
          end
        end
    end
  end
end

require File.join(File.dirname(__FILE__), "transformer", "runner")
