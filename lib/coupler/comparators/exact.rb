module Coupler
  module Comparators
    class Exact < Base
      OPTIONS = [
        {:label => "Field", :name => "field_name", :type => "text"}
      ]
      LIMIT = 1000

      def self.field_arity
        :infinite
      end

      def score(score_set, *datasets)
        case datasets.length
        when 1
          last_value = nil
          last_key = nil
          datasets[0].order(@field_names[0]).each do |record|
            value = record[@field_names[0]]
            key = record[@keys[0]]
            if value != last_value
              last_value = value
              last_key = record[@keys[0]]
            else
              score_set.insert_or_update({
                :first_id => last_key, :second_id => key,
                :score => 100
              })
            end
          end
        when 2
          # FIXME: Hey, maybe do a join instead, dummy?

          ## What's happening here:
          # 1. First sort both datasets on the field(s) in question
          # 2. Walk down the first dataset until there's a matching row in the
          #    second dataset
          # 3. When there's a match, walk down the second dataset until there
          #    are no more matches, saving each id in the second dataset that
          #    matches
          # 4. Walk down the first dataset again.  For each row that matches
          #    the previous first dataset row, record scores for the matching
          #    ids in the second dataset that we saved

          counts, records, values, previous_values, keys = [], [], [], [], []
          offsets, indices, completed = [0, 0], [0, 0], [0, 0]
          datasets.each_with_index do |ds, i|
            datasets[i] = ds.select(@keys[i], @field_names[i]).order(@field_names[i])
            counts << datasets[i].count
            records << datasets[i].limit(LIMIT, 0).all
            values << records[i][0][@field_names[i]]
            previous_values << nil
            keys << records[i][0][@keys[i]]
          end

          advance = previous_advance = nil
          matching_second_ids = []
          while completed[0] < counts[0] && completed[1] < counts[1]
            if values[0].nil?
              advance = 0
            elsif values[1].nil?
              advance = 1
            elsif values[0] < values[1]
              # if the value for the previous dataset 1 row is the same as
              # this one, record matching scores for all the matching ids
              # from the previous row
              if previous_advance == 0 && values[0] == previous_values[1]
                matching_second_ids.each do |second_id|
                  score_set.insert_or_update({
                    :first_id => keys[0], :second_id => second_id,
                    :score => 100
                  })
                end
              end

              # advance dataset 1
              advance = 0
            else
              if values[1] != previous_values[1]
                # reset matching ids
                matching_second_ids.clear
              end

              if values[0] == values[1]
                score_set.insert_or_update({
                  :first_id => keys[0], :second_id => keys[1],
                  :score => 100
                })
                matching_second_ids << keys[1]
              end

              # advance dataset 2
              advance = 1
            end

            completed[advance] += 1
            indices[advance] += 1
            if indices[advance] == LIMIT
              # fetch more records
              offsets[advance] += LIMIT
              indices[advance] = 0
              if offsets[advance] < counts[advance]
                records[advance] = datasets[advance].limit(LIMIT, offsets[advance]).all
              end
            end

            previous_values[advance] = values[advance]
            row = records[advance][indices[advance]]
            if row
              values[advance] = row[@field_names[advance]]
              keys[advance]   = row[@keys[advance]]
            end
            previous_advance = advance    # this is only for readability
          end
        end
      end
    end
    self.register("exact", Exact)
  end
end
