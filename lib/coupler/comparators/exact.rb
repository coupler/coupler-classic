module Coupler
  module Comparators
    class Exact < Base
      LIMIT = 1000
      MATCHING_SCORE = 100

      def self.field_arity
        :infinite
      end

      def add_match(score_set, matches, first_id, second_id)
        matches.push([first_id, second_id, MATCHING_SCORE, @matcher_id])
        if matches.length == 1000
          flush_matches(score_set, matches)
        end
      end

      def flush_matches(score_set, matches)
        score_set.import([:first_id, :second_id, :score, :matcher_id], matches)
        matches.clear
      end

      def score(score_set, *datasets)
        join_array = []
        if datasets.length == 1
          key_name = @keys[0]
          if @field_names.all? { |f| !f.is_a?(Array) }
            # This happens when there is no cross-matching (such as matching
            # first name to last name within the same dataset, for example).
            # This is the only case that doesn't involve a join.

            filter = @field_names.inject({}) { |h, f| h[f] = nil; h }
            dataset = datasets[0].select(*([key_name]+@field_names)).
              filter(~filter).order(*@field_names)

            last_value = nil
            last_key = nil
            matches = []
            offset = 0
            loop do
              set = dataset.limit(LIMIT, offset)
              offset += LIMIT

              count = 0
              set.each do |record|
                value = record.values_at(*@field_names)
                key = record[key_name]
                if value != last_value
                  last_value = value
                  last_key = key
                else
                  add_match(score_set, matches, last_key, key)
                end
                count += 1
              end
              break if count < LIMIT
            end
            flush_matches(score_set, matches)
            return
          else
            # Single dataset with multiple fields; do a self-join
            join_array.push(~{:"t2__#{key_name}" => :"t1__#{key_name}"})
            datasets[1] = datasets[0].clone
            @keys[1] = key_name
          end
        end

        join_hash = {}
        filter_array = []
        @field_names.each do |obj|
          # For the filter array, is there any reason to 
          case obj
          when Symbol
            join_hash[:"t2__#{obj}"] = :"t1__#{obj}"
            filter_array.push(~{:"t1__#{obj}" => nil, :"t2__#{obj}" => nil})
          when Array
            join_hash[:"t2__#{obj[1]}"] = :"t1__#{obj[0]}"
            filter_array.push(~{:"t1__#{obj[0]}" => nil, :"t2__#{obj[1]}" => nil})
          end
        end
        join_array.push(join_hash)

        dataset = datasets[0].from(datasets[0].first_source_table => :t1).
          join(datasets[1].first_source_table, join_array, :table_alias => :t2).
          select(:"t1__#{@keys[0]}" => :first_id, :"t2__#{@keys[1]}" => :second_id).
          filter(*filter_array).order(:"t1__#{@keys[0]}", :"t2__#{@keys[1]}")
        offset = 0

        matches = []
        loop do
          set = dataset.limit(LIMIT, offset)
          offset += LIMIT

          count = 0
          set.each do |row|
            add_match(score_set, matches, row[:first_id], row[:second_id])
            count += 1
          end
          break if count < LIMIT
        end
        flush_matches(score_set, matches)
      end

    end
    self.register("exact", Exact)
  end
end
