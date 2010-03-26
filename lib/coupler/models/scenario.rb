module Coupler
  module Models
    class Scenario < Sequel::Model
      include CommonModel
      attr_writer :resource_ids
      many_to_one :project
      many_to_one :resource_1, :class => Models::Resource
      many_to_one :resource_2, :class => Models::Resource
      one_to_many :matchers
      one_to_many :jobs
      one_to_many :results

      def status
        if self.matchers_dataset.count == 0
          "no_matchers"
        elsif self.linkage_type == "N/A"
          "no_resources"
        elsif self.resource_1.status == "out_of_date" ||
            (self.resource_2 && self.resource_2.status == "out_of_date")
          "resources_out_of_date"
        else
          "ok"
        end
      end

      def resources
        if resource_1
          resource_2 ? [resource_1, resource_2] : [resource_1]
        else
          []
        end
      end

      def run!
        runner = case self.linkage_type
                 when "self-linkage"
                   SingleRunner.new(self)
                 when "dual-linkage"
                   DualRunner.new(self)
                 end

        result = Result.new(:scenario => self)
        ScoreSet.create do |score_set|
          result[:score_set_id] = score_set.id
          runner.run(score_set)
        end
        result.save

        self.update(:last_run_at => Time.now)
      end

      private
        def before_create
          super
          self.slug ||= self.name.downcase.gsub(/\s+/, "_")

          if @resource_ids.is_a?(Array)
            objects = self.project.resources_dataset.filter(:id => @resource_ids[0..1].compact).all
            self.resource_1 = objects[0]
            self.resource_2 = objects[1]
          end
          set_linkage_type
        end

        def before_update
          super
          set_linkage_type
        end

        def set_linkage_type
          self.linkage_type = if resource_1
                                resource_2 ? "dual-linkage" : "self-linkage"
                              else
                                "N/A"
                              end
        end

        def validate
          if self.name.nil? || self.name == ""
            errors[:name] << "is required"
          else
            if self.new?
              count = self.class.filter(:name => self.name).count
              errors[:name] << "is already taken"   if count > 0
            else
              count = self.class.filter(["name = ? AND id != ?", self.name, self.id]).count
              errors[:name] << "is already taken"   if count > 0
            end
          end
        end
    end
  end
end

require File.join(File.dirname(__FILE__), 'scenario', 'runner')
