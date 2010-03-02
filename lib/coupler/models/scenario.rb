module Coupler
  module Models
    class Scenario < Sequel::Model
      include CommonModel
      attr_writer :resource_ids
      many_to_one :project
      many_to_many :resources
      one_to_many :matchers

      def linkage_type
        case self.resources_dataset.count
        when 1
          "self-linkage"
        when 2
          "dual-linkage"
        else
          "N/A"
        end
      end

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
        case self.resources_dataset.count
        when 1
          resource = self.resources_dataset.first
          comparators = matchers.collect do |matcher|
            klass = Comparators[matcher.comparator_name]
            klass.new(matcher.comparator_options[resource.id.to_s])
          end
          key = resource.primary_key_name.to_sym
          resource.final_dataset do |dataset|
            dataset = dataset.order(key)

            num = dataset.count
            self.update(:completed => 0, :total => num * (num - 1) / 2)

            thread_pool = ThreadPool.new(10)
            ScoreSet.create do |score_set|
              self.update(:score_set_id => score_set.id)
              dataset.each do |record_1|
                dataset.filter("#{key} > ?", record_1[key]).each do |record_2|
                  thread_pool.execute(record_1, record_2) do |first, second|
                    result = comparators.inject(0) do |score, comparator|
                      score + comparator.score(first, second)
                    end
                    score_set.insert({
                      :first_id => first[key], :second_id => second[key],
                      :score => result
                    })
                    self.class.filter(:id => self.id).update("completed = completed + 1")
                  end
                end
              end
              thread_pool.join
            end
          end
        when 2
          resource_1, resource_2 = self.resources_dataset.limit(2).order(:id).all
          comparators = matchers.collect do |matcher|
            klass = Comparators[matcher.comparator_name]
            options = Hash.new { |h, k| h[k] = [] }
            matcher.comparator_options.values_at(resource_1.id.to_s, resource_2.id.to_s).each do |ropts|
              ropts.each_pair { |k, v| options[k] << v }
            end
            klass.new(options)
          end
          key_1 = resource_1.primary_key_name.to_sym
          key_2 = resource_2.primary_key_name.to_sym
          resource_1.final_dataset do |dataset_1|
            dataset_1 = dataset_1.order(key_1)

            resource_2.final_dataset do |dataset_2|
              dataset_2 = dataset_2.order(key_2)

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
                        :first_id => first[key_1], :second_id => second[key_2],
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

        def after_create
          super
          if @resource_ids.is_a?(Array)
            @resource_ids.each do |resource_id|
              resource = self.project.resources_dataset[:id => resource_id]
              self.add_resource(resource)   if resource
            end
          end
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
