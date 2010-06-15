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

          def add_condition(array, lhs, rhs, operator)
            case operator
            when "=", "!="
              hash = {lhs => rhs}
              array.push(operator == "=" ? hash : ~hash)
            else
              array.push(lhs.send(operator, rhs))
            end
          end

          def score(score_set, matcher, *datasets)
            matcher_id = matcher.id
            join_array = []
            filter_array = []
            if datasets.length == 1
              # Self-join
              join_array.push(:"t1__#{@keys[0]}" < :"t2__#{@keys[0]}")
              datasets[1] = datasets[0].clone
              @keys[1] = @keys[0]
            end

            matcher.comparisons.each do |comparison|
              types = [comparison.lhs_type, comparison.rhs_type]
              lhs_value = comparison.lhs_value
              if types[0] == 'field'
                which = comparison.lhs_which || 1
                lhs_value = :"t#{which}__#{lhs_value.name}"
                expr = ~{lhs_value => nil}
                filter_array.push(expr)   unless filter_array.include?(expr)
              end

              rhs_value = comparison.rhs_value
              if types[1] == 'field'
                which = comparison.rhs_which || 2
                rhs_value = :"t#{which}__#{rhs_value.name}"
                expr = ~{rhs_value => nil}
                filter_array.push(expr)   unless filter_array.include?(expr)
              end

              operator = comparison.operator_symbol

              if types[0] == 'field' && types[1] == 'field'
                add_condition(join_array, lhs_value, rhs_value, operator)
              elsif which = types.index("field")
                if which == 0
                  add_condition(filter_array, lhs_value, rhs_value, operator)
                else
                  # flip the operator
                end
              end
            end

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
