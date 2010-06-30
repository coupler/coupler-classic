module Coupler
  module Models
    class Resource
      class Importer
        attr_reader :columns, :data, :filename

        def initialize(file, original_filename = nil)
          @csv = FasterCSV.new(file, :headers => true)
          @filename = original_filename || File.basename(file.path)
          discover_columns
        end

        private
          def discover_columns
            @data = []
            types = Hash.new { |a, b| a[b] = Hash.new { |c, d| c[d] = 0 } }
            50.times do |i|
              row = @csv.shift
              break   if row.nil?

              @data << row
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
            @columns = types.collect do |(col, counts)|
              info = { :type => counts.max { |a, b| a[1] <=> b[1] }[0] }
              if col =~ /^id$/i && !primary_key_found
                info[:primary_key] = true
                primary_key_found = true
              end
              [col, info]
            end
          end
      end
    end
  end
end
