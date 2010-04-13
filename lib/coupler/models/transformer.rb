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
          rescue Exception => e
            result[type][:out] = e
            result['success'] = false
          end
        end
        result
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
