module Coupler
  module Models
    class Scenario
      class Runner
        LIMIT = 1000
        MATCHING_SCORE = 100

        def initialize(parent)
          @parent = parent
          @thread_pool = ThreadPool.new(10)
          setup_resources
          @keys = @resources.collect { |r| r.primary_key_name.to_sym }
        end

        def run(*args)
          raise NotImplementedError
        end

        protected
          def setup_resources
            raise NotImplementedError
          end

          def add_match(score_set, matches, first_id, second_id, matcher_id)
            matches.push([first_id, second_id, MATCHING_SCORE, matcher_id])
            if matches.length == 1000
              flush_matches(score_set, matches)
            end
          end

          def flush_matches(score_set, matches)
            score_set.import([:first_id, :second_id, :score, :matcher_id], matches)
            matches.clear
          end

          def score(score_set, matcher, *datasets)
            matcher_id = matcher.id
            join_array = []
            filter_array = []
            if datasets.length == 1
              key_name = @keys[0]
              join_needed = matcher.comparisons.any? do |comparison|
                comparison.lhs_type == 'field' &&
                  comparison.rhs_type == 'field' &&
                  comparison.raw_lhs_value != comparison.raw_rhs_value
              end

              if !join_needed
                # This happens when there are no cross-comparisons within the
                # same dataset (such as comparing first name to last name, for
                # example).  This is the only case that doesn't involve a join.

                select = [key_name]
                filter = {}
                field_names = []
                matcher.comparisons.each do |comparison|
                  comparison.fields.each do |field|
                    name = field.name.to_sym
                    select << name
                    filter[name] = nil  # weed out nils (FIXME: don't hardcode)
                    field_names << name
                  end
                end
                dataset = datasets[0].select(*select).filter(~filter).order(*field_names)

                last_value = nil
                keys = []
                matches = []
                offset = 0
                loop do
                  set = dataset.limit(LIMIT, offset)
                  offset += LIMIT

                  count = 0
                  set.each do |record|
                    value = record.values_at(*field_names)
                    key = record[key_name]
                    if value != last_value
                      last_value = value
                      keys.clear
                      keys << key
                    else
                      keys.each { |k| add_match(score_set, matches, k, key, matcher_id) }
                      keys << key
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
                filter_array.push(:"t2__#{key_name}" > :"t1__#{key_name}")
                datasets[1] = datasets[0].clone
                @keys[1] = key_name
              end
            end

            join_hash = {}
            matcher.comparisons.each do |comparison|
              field_names = comparison.fields.collect(&:name)
              join_hash[:"t2__#{field_names[1]}"] = :"t1__#{field_names[0]}"
              filter_array.push(~{:"t1__#{field_names[0]}" => nil, :"t2__#{field_names[1]}" => nil})
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
                add_match(score_set, matches, row[:first_id], row[:second_id], matcher_id)
                count += 1
              end
              break if count < LIMIT
            end
            flush_matches(score_set, matches)
          end
      end

      class SingleRunner < Runner
        def setup_resources
          @resources = [@parent.resource_1]
        end
        protected(:setup_resources)

        def run(score_set)
          @resources[0].final_dataset do |dataset|
            # FIXME: add this back somehow
            #num = dataset.count
            #@parent.update(:completed => 0, :total => num * (num - 1) / 2)

            @parent.matchers.each do |matcher|
              score(score_set, matcher, dataset)
            end
          end
        end
      end

      class DualRunner < Runner
        def setup_resources
          @resources = [@parent.resource_1, @parent.resource_2]
        end

        def run(score_set)
          @resources[0].final_dataset do |dataset_1|
            @resources[1].final_dataset do |dataset_2|
              # FIXME: add this back somehow
              #num = dataset_1.count * dataset_2.count
              #self.update(:completed => 0, :total => num)

              @parent.matchers.each do |matcher|
                score(score_set, matcher, dataset_1, dataset_2)
              end
            end
          end
        end
      end
    end
  end
end
