module Coupler
  module Models
    class Scenario
      class RecordMatcher
        def initialize(group_counter, groups_buffer, groups_records_buffer, resource, matcher, pairs, which)
          @groups_buffer = groups_buffer
          @groups_records_buffer = groups_records_buffer
          @group_counter = group_counter
          @resource_id = resource.id
          @matcher_id = matcher.id
          @key = resource.primary_key_name.to_sym

          if which
            # only compare one side; this is for dual-linkage
            @pairs = pairs.collect { |p| [p[which], p[which]] }
          else
            @pairs = pairs
          end
        end

        def compare(row_1, row_2)
          #@mutex.synchronize { p [row_1, row_2] }
          result = nil
          @pairs.each do |field_1, field_2|
            result = row_1[field_1.name_sym] <=> row_2[field_2.name_sym]
            break   if result != 0
          end
          result
        end

        # Save two already compared rows
        def save(row_1, row_2, group_id)
          id_1 = row_1[@key]; id_2 = row_2[@key]

          if group_id.nil?
            group_id = @group_counter.next_group
            group_row = [group_id, @resource_id, @matcher_id]
            @pairs.each do |(field_1, field_2)|
              group_row << row_1[field_1.name_sym]
              group_row << row_1[field_2.name_sym]  if field_2 != field_1
            end
            @groups_buffer.add(group_row)
            @records_groups_buffer.add([id_1, group_id])
          end
          @records_groups_buffer.add([id_2, group_id])
          group_id
        end

        def compare_and_save(row_1, row_2, group_id)
          result = compare(row_1, row_2)
          if result == 0
            group_id = save(row_1, row_2, group_id)
          else
            group_id = nil
          end
          group_id
        end
      end
    end
  end
end
