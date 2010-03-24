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

      def linkage_type
        if self.resource_1
          self.resource_2 ? "dual-linkage" : "self-linkage"
        else
          "N/A"
        end
      end

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
        ScoreSet.create do |score_set|
          self.update(:score_set_id => score_set.id)
          runner.run(score_set)
        end
        self.update(:run_at => Time.now)
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

require File.join(File.dirname(__FILE__), 'scenario', 'runner')
