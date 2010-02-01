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
        case self[:type]
        when "self-join"
          resource = self.resources_dataset.first
          comparators = matchers.collect do |matcher|
            klass = Comparators[matcher.comparator_name]
            klass.new(matcher.comparator_options[resource.id.to_s])
          end
          resource.final_dataset do |dataset|
            dataset = dataset.order(:id) # FIXME: id

            num = dataset.count
            self.update(:completed => 0, :total => num * (num - 1) / 2)

            thread_pool = ThreadPool.new(10)
            ScoreSet.create do |score_set|
              self.update(:score_set_id => score_set.id)
              dataset.each do |record_1|
                dataset.filter("id > ?", record_1[:id]).each do |record_2|
                  thread_pool.execute(record_1, record_2) do |first, second|
                    result = comparators.inject(0) do |score, comparator|
                      score + comparator.score(first, second)
                    end
                    score_set.insert({
                      :first_id => first[:id], :second_id => second[:id],
                      :score => result
                    })
                    self.class.filter(:id => self.id).update("completed = completed + 1")
                  end
                end
              end
              thread_pool.join
            end
          end
        when "dual-join"
          resource_1, resource_2 = self.resources_dataset.limit(2).order(:id).all
          comparators = matchers.collect do |matcher|
            klass = Comparators[matcher.comparator_name]
            options = Hash.new { |h, k| h[k] = [] }
            matcher.comparator_options.values_at(resource_1.id.to_s, resource_2.id.to_s).each do |ropts|
              ropts.each_pair { |k, v| options[k] << v }
            end
            klass.new(options)
          end
          resource_1.final_dataset do |dataset_1|
            dataset_1 = dataset_1.order(:id) # FIXME: id

            resource_2.final_dataset do |dataset_2|
              dataset_2 = dataset_2.order(:id) # FIXME: id

              num = dataset_1.count * dataset_2.count
              self.update(:completed => 0, :total => num)

              thread_pool = ThreadPool.new(10)
              ScoreSet.create do |score_set|
                self.update(:score_set_id => score_set.id)
                dataset_1.each do |record_1|
                  dataset_2.each do |record_2|
                    thread_pool.execute(record_1, record_2) do |first, second|
                      result = comparators.inject(0) do |score, comparator|
                        score + comparator.score(first, second)
                      end
                      score_set.insert({
                        :first_id => first[:id], :second_id => second[:id],
                        :score => result
                      })
                      self.class.filter(:id => self.id).update("completed = completed + 1")
                    end
                  end
                end
                thread_pool.join
              end
            end
          end
        end

        self.update(:run_at => Time.now)
      end

      private
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
