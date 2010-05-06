module Coupler
  module Comparators
    class Exact < Base
      LIMIT = 1000

      def self.field_arity
        :infinite
      end

      def score(score_set, *datasets)
        if datasets.length == 1
          if @field_names.all? { |f| !f.is_a?(Array) }
            # This happens when there is no cross-matching, like matching
            # first name to last name within the same dataset, for example.
            # This is the only case that doesn't involve a join.

            key_name = @keys[0]
            last_value = nil
            last_key = nil
            datasets[0].select(*([key_name]+@field_names)).order(*@field_names).each do |record|
              value = record.values_at(*@field_names)
              key = record[key_name]
              if value != last_value
                last_value = value
                last_key = key
              else
                score_set.insert_or_update({
                  :first_id => last_key, :second_id => key,
                  :score => 100
                })
              end
            end
            return
          else
            # Single dataset with multiple fields; do a self-join
          end
        end

        join_hash = @field_names.inject({}) do |hash, obj|
          case obj
          when Symbol
            hash[obj] = obj
          when Array
            hash[obj[1]] = obj[0]
          end
          hash
        end

        dataset = datasets[0].from(datasets[0].first_source_table => :t1).
          join(datasets[1].first_source_table, join_hash, :table_alias => :t2).
          select(:"t1__#{@keys[0]}" => :first_id, :"t2__#{@keys[1]}" => :second_id).
          order(:"t1__#{@keys[0]}", :"t2__#{@keys[1]}")
        offset = 0

        loop do
          matches = dataset.limit(LIMIT, offset)
          offset += LIMIT

          count = 0
          matches.each do |row|
            score_set.insert_or_update(row.merge(:score => 100))
            count += 0
          end
          break if count < LIMIT
        end
      end

    end
    self.register("exact", Exact)
  end
end
