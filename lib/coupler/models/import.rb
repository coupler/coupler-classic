module Coupler
  module Models
    class Import < Sequel::Model
      include CommonModel

      mount_uploader :data, DataUploader
      plugin :serialization, :marshal, :fields

      def preview
        if @preview.nil?
          @preview = []
          FasterCSV.foreach(data.current_path, :headers => true) do |row|
            break if @preview.length == 50
            @preview << row
          end
        end
        @preview
      end

      private
        def discover_fields
          types = Hash.new { |a, b| a[b] = Hash.new { |c, d| c[d] = 0 } }
          preview.each do |row|
            row.each do |col, value|
              case value
              when /^\d+$/
                types[col][:integer] += 1
              else
                types[col][:string] += 1
              end
            end
          end

          primary_key_found = false
          self.fields = types.collect do |(col, counts)|
            info = { :type => counts.max { |a, b| a[1] <=> b[1] }[0] }
            if col =~ /^id$/i && !primary_key_found
              info[:primary_key] = true
              primary_key_found = true
            end
            [col, info]
          end
        end

        def before_save
          super
          discover_fields
        end
    end
  end
end
