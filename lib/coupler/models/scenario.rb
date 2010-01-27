module Coupler
  module Models
    class Scenario < Sequel::Model
      include CommonModel
      many_to_one :project
      many_to_many :resources
      one_to_many :matchers

      def status
        if self.matchers_dataset.count == 0
          "no_matchers"
        elsif self.resources_dataset.count == 0
          "no_resources"
        elsif self.resources.any? { |r| r.status == "out_of_date" }
          "resources_out_of_date"
        else
          "ok"
        end
      end

      def run!
        @score_set = ScoreSet.create
        self.update(:score_set_id => @score_set.id)

        # self-join
        resource = self.resources_dataset.first
        resource.final_dataset do |dataset|
          dataset = dataset.order(:id) # FIXME: id

          num = dataset.count
          self.update(:completed => 0, :total => num * (num - 1) / 2)

          thread_pool = ThreadPool.new(10)
          dataset.each do |record_1|
            dataset.filter("id > ?", record_1[:id]).each do |record_2|
              thread_pool.execute(record_1, record_2) do |first, second|
                result = comparators.inject(0) do |score, comparator|
                  score + comparator.score(first, second)
                end
                @score_set.insert({
                  :first_id => first[:id], :second_id => second[:id],
                  :score => result
                })
                self.class.filter(:id => self.id).update("completed = completed + 1")
              end
            end
          end
          thread_pool.join

          self.update(:run_at => Time.now)
        end
      end

      private
        def comparators
          @comparators ||= matchers.collect do |matcher|
            klass = Comparators[matcher.comparator_name]
            klass.new(matcher.comparator_options)
          end
        end

        def before_create
          super
          self.slug ||= self.name.downcase.gsub(/\s+/, "_")
        end

        def validate
          if self.name.nil? || self.name == ""
            errors[:name] << "is required"
          else
            obj = self.class[:name => name]
            if self.new?
              errors[:name] << "is already taken"   if obj
            else
              errors[:name] << "is already taken"   if obj.id != self.id
            end
          end
        end
    end
  end
end
