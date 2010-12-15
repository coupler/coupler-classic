module Coupler
  module Models
    class Import < Sequel::Model
      include CommonModel

      # NOTE: yoinked from FasterCSV
      # A Regexp used to find and convert some common Date formats.
      DateMatcher     = / \A(?: (\w+,?\s+)?\w+\s+\d{1,2},?\s+\d{2,4} |
                                \d{4}-\d{2}-\d{2} )\z /x
      # A Regexp used to find and convert some common DateTime formats.
      DateTimeMatcher =
        / \A(?: (\w+,?\s+)?\w+\s+\d{1,2}\s+\d{1,2}:\d{1,2}:\d{1,2},?\s+\d{2,4} |
                \d{4}-\d{2}-\d{2}\s\d{2}:\d{2}:\d{2} )\z /x

      many_to_one :project
      mount_uploader :data, DataUploader
      plugin :serialization
      serialize_attributes :marshal, :field_types, :field_names

      def preview
        if @preview.nil?
          @preview = []
          FasterCSV.open(data.current_path) do |csv|
            csv.shift   if self.has_headers
            50.times do |i|
              row = csv.shift
              if row
                @preview << row
              else
                break
              end
            end
          end
        end
        @preview
      end

      def import!
        project.local_database do |db|
          column_info = []
          column_names = []
          column_types = []
          field_names.each_with_index do |name, i|
            name_sym = name.to_sym
            column_names << name_sym
            column_types << {
              :name => name_sym,
              :type =>
                case field_types[i]
                when 'integer' then Integer
                when 'string' then String
                end
            }
          end
          table_name = :"import_#{id}"
          db.create_table!(table_name) do
            columns.push(*column_types)
          end

          ds = db[table_name]
          key_frequencies = Hash.new { |h, k| h[k] = 0 }
          duplicate_keys_found = false
          rows = []
          total = 0
          primary_key_index = field_names.index(primary_key_name)
          csv = FasterCSV.foreach(data.current_path) do |row|
            total += 1
            next  if total == 1   # ignore the header

            key = row[primary_key_index]
            key_frequencies[key] += 1
            duplicate_keys_found = true if key_frequencies[key] > 1

            rows << row
            if rows.length == 1000
              ds.import(column_names, rows)
              rows.clear
            end
          end
          ds.import(column_names, rows)   unless rows.empty?

          primary_key_sym = primary_key_name.to_sym
          if duplicate_keys_found
            # flag duplicate primary keys
            db.alter_table(table_name) { add_column(:dup_key, TrueClass) }
            key_frequencies.each_pair do |key, count|
              next  if count == 1
              ds.filter(primary_key_sym => key).update(:dup_key => true)
            end
          else
            # alter table to set primary key
            db.alter_table(table_name) { add_primary_key([primary_key_sym]) }
          end
        end
      end

      private
        def discover_fields
          types = []
          type_counts = []
          headers = nil
          FasterCSV.open(data.current_path) do |csv|
            headers = csv.shift
            count = 0
            if headers.any? { |h| h !~ /[A-Za-z_$]/ }
              row = headers
              headers = nil
              self.has_headers = false
            else
              self.has_headers = true
              headers.each_with_index do |name, i|
                if name =~ /^id$/i
                  self.primary_key_name = name
                end
              end
              row = csv.shift
            end

            while row && count < 50
              row.each_with_index do |value, i|
                hash = type_counts[i] ||= {}
                type =
                  case value
                  when /^\d+$/ then 'integer'
                  else 'string'
                  end
                hash[type] = (hash[type] || 0) + 1
              end
              row = csv.shift
              count += 1
            end
          end

          type_counts.each_with_index do |type_count, i|
            types[i] = type_count.max { |a, b| a[1] <=> b[1] }[0]
          end

          self.field_types = types
          self.field_names = headers
        end

        def validate
          super
          if !new?
            validates_presence [:field_names, :primary_key_name]
            if field_names.is_a?(Array)
              validates_includes field_names, [:primary_key_name]

              expected = field_types.length
              if field_names.length != expected
                errors.add(:field_names, "must be of length #{expected}")
              end

              # check for duplicate field names
              duplicates = {}
              field_names.inject(Hash.new(0)) do |hash, field_name|
                num = hash[field_name] += 1
                duplicates[field_name] = num  if num > 1
                hash
              end
              if !duplicates.empty?
                message = "have duplicates (%s)" %
                  duplicates.inject("") { |s, (k, v)| s + "#{k} x #{v}, " }.chomp(", ")
                errors.add(:field_names, message)
              end
            end
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
