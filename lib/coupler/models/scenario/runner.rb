module Coupler
  module Models
    class Scenario
      class Runner
        def initialize(parent)
          @parent = parent
          @thread_pool = ThreadPool.new(10)
          setup_resources
          @keys = @resources.collect { |r| r.primary_key_name.to_sym }
          setup_comparators
        end

        protected
          def setup_resources
            raise NotImplementedError
          end

          def setup_comparators
            @comparators = {:simple => [], :normal => []}
            @parent.matchers.each do |matcher|
              klass = Comparators[matcher.comparator_name]

              options = {
                'keys' => @keys,
                'field_names' => matcher.comparisons.collect do |comparison|
                  field_1 = comparison.field_1
                  field_2 = comparison.field_2
                  if field_1.name == field_2.name
                    field_1.name
                  else
                    [field_1.name, field_2.name]
                  end
                end
              }
              object = klass.new(options)
              if klass.scoring_method == :simple_score
                @comparators[:simple] << object
              else
                @comparators[:normal] << object
              end
            end
          end
      end

      class SingleRunner < Runner
        def setup_resources
          @resources = [@parent.resource_1]
        end
        protected(:setup_resources)

        def run(score_set)
          @resources[0].final_dataset do |dataset|
            dataset = dataset.order(@keys[0])

            # FIXME: add this back somehow
            #num = dataset.count
            #@parent.update(:completed => 0, :total => num * (num - 1) / 2)

            if !@comparators[:simple].empty?
              dataset.each do |record_1|
                dataset.filter("#{@keys[0]} > ?", record_1[@keys[0]]).each do |record_2|
                  @thread_pool.execute(record_1, record_2) do |first, second|
                    result = @comparators[:simple].inject(0) do |score, comparator|
                      score + comparator.score(first, second)
                    end

                    score_set.insert_or_update({
                      :first_id => first[@keys[0]], :second_id => second[@keys[0]],
                      :score => result
                    })
                    # FIXME: add this back somehow
                    #@parent.class.filter(:id => @parent.id).update("completed = completed + 1")
                  end
                end
              end
            end

            @comparators[:normal].each do |comparator|
              comparator.score(score_set, dataset)
            end

            @thread_pool.join
          end
        end
      end

      class DualRunner < Runner
        def setup_resources
          @resources = [@parent.resource_1, @parent.resource_2]
        end

        def run(score_set)
          @resources[0].final_dataset do |dataset_1|
            dataset_1 = dataset_1.order(@keys[0])

            @resources[1].final_dataset do |dataset_2|
              dataset_2 = dataset_2.order(@keys[1])

              # FIXME: add this back somehow
              #num = dataset_1.count * dataset_2.count
              #self.update(:completed => 0, :total => num)

              if !@comparators[:simple].empty?
                dataset_1.each do |record_1|
                  dataset_2.each do |record_2|
                    @thread_pool.execute(record_1, record_2) do |first, second|
                      result = @comparators[:simple].inject(0) do |score, comparator|
                        score + comparator.score(first, second)
                      end
                      score_set.insert({
                        :first_id => first[@keys[0]], :second_id => second[@keys[1]],
                        :score => result
                      })

                      # FIXME: add this back somehow
                      #self.class.filter(:id => self.id).update("completed = completed + 1")
                    end
                  end
                end
              end

              @comparators[:normal].each do |comparator|
                comparator.score(score_set, dataset_1, dataset_2)
              end

              @thread_pool.join
            end
          end
        end
      end
    end
  end
end
