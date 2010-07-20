module Coupler
  module Models
    class Import < Sequel::Model
      include CommonModel

      many_to_one :project
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

      def field_types=(hash)
        hash.each_pair do |name, info|
          fields.each_index do |i|
            next  if fields[i][0] != name
            if info['type']
              fields[i][1][:type] = info['type'].to_sym
            end
            break
          end
        end
      end

      def primary_key=(name)
        fields.each_index do |i|
          if fields[i][0] == name
            fields[i][1][:primary_key] = true
          else
            fields[i][1].delete(:primary_key)
          end
        end
      end

      def import!
        project.local_database do |db|
          column_info = []
          column_names = []
          fields.each do |(name, info)|
            name = name.to_sym
            column_names << name
            column_info << info.merge({
              :name => name,
              :type =>
                case info[:type]
                when :integer then Integer
                when :string then String
                end
            })
          end
          table_name = :"import_#{id}"
          db.create_table!(table_name) do
            columns.push(*column_info)
          end

          ds = db[table_name]
          rows = []
          total = 0
          csv = FasterCSV.foreach(data.current_path) do |row|
            total += 1
            next  if total == 1   # ignore the header

            rows << row
            if rows.length == 1000
              ds.import(column_names, rows)
              rows.clear
            end
          end
          ds.import(column_names, rows)   unless rows.empty?
        end
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
          if new?
            self.name = File.basename(data.current_path).sub(/\.\w+?$/, "").gsub(/[_-]+/, " ").capitalize
            discover_fields
          end
          super
        end
    end
  end
end
