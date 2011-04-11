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
      plugin :serialization
      serialize_attributes :marshal, :field_types, :field_names
      mount_uploader :data, DataUploader

      def data=(value)
        result = super
        self.name ||= File.basename(data.file.original_filename).sub(/\.\w+?$/, "").gsub(/[_-]+/, " ").capitalize
        discover_fields
        result
      end

      def primary_key_sym
        primary_key_name.to_sym
      end

      def table_name
        :"import_#{id}"
      end

      def preview
        if @preview.nil?
          @preview = []
          FasterCSV.open(data.file.file) do |csv|
            csv.rewind
            csv.shift   if self.has_headers
            50.times do |i|
              row = csv.shift
              break if row.nil?
              @preview << row
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
          column_names << :dup_key_count
          column_types << {:name => :dup_key_count, :type => Integer}
          db.create_table!(table_name) do
            columns.push(*column_types)
          end

          ds = db[table_name]
          key_frequencies = Hash.new { |h, k| h[k] = 0 }
          buffer = ImportBuffer.new(column_names, ds)
          skip = has_headers
          primary_key_index = field_names.index(primary_key_name)
          FasterCSV.foreach(data.file.file) do |row|
            if skip
              # skip header if necessary
              skip = false
              next
            end

            key = row[primary_key_index]
            num = key_frequencies[key] += 1
            row.push(num > 1 ? num : nil)
            self.has_duplicate_keys = true if num > 1

            buffer.add(row)
          end
          buffer.flush

          primary_key = self.primary_key_sym
          if has_duplicate_keys
            # flag duplicate primary keys
            key_frequencies.each_pair do |key, count|
              next  if count == 1
              ds.filter(primary_key => key, :dup_key_count => nil).update(:dup_key_count => 1)
            end
          else
            # alter table to set primary key
            db.alter_table(table_name) do
              drop_column(:dup_key_count)
              add_primary_key([primary_key])
            end
          end
        end
        update(:occurred_at => Time.now)
        !has_duplicate_keys
      end

      def dataset
        project.local_database do |db|
          yield(db[table_name])
        end
      end

      def repair_duplicate_keys!(rows_to_remove = nil)
        pkey = primary_key_sym
        project.local_database do |db|
          ds = db[table_name]
          if rows_to_remove
            filtered_ds = nil
            rows_to_remove.each_pair do |key, dups|
              hsh = {pkey => key, :dup_key_count => dups}
              filtered_ds = filtered_ds ? filtered_ds.or(hsh) : ds.filter(hsh)
            end
            filtered_ds.delete if filtered_ds
          end

          # only reassign keys if there is more than 1 duplicate per key
          keys = ds.group(pkey).having { count(pkey) > 1 }.select_map(pkey)

          current_key = nil
          next_key = ds.order(pkey).last[pkey].next
          ds.filter(pkey => keys).order(:dup_key_count).each do |row|
            # skip the first one, since it'll retain the key
            if current_key != row[pkey]
              current_key = row[pkey]
            else
              ds.filter(pkey => row[pkey], :dup_key_count => row[:dup_key_count]).
                update(pkey => next_key)
              next_key = next_key.next
            end
          end

          db.alter_table(table_name) do
            drop_column(:dup_key_count)
            add_primary_key([pkey])
          end
        end
      end

      private
        def discover_fields
          FasterCSV.open(data.file.file) do |csv|
            csv.rewind

            count = 0
            types = []
            type_counts = []
            headers = csv.shift
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

            type_counts.each_with_index do |type_count, i|
              types[i] = type_count.max { |a, b| a[1] <=> b[1] }[0]
            end

            self.field_types = types
            self.field_names = headers
          end
        end

        def validate
          super

          # don't allow import to have the same name as an already existing resource
          if project.resources_dataset.filter(:name => name).count > 0
            errors.add(:name, "is already taken")
          end

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
  end
end
