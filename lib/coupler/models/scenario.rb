module Coupler
  module Models
    class Scenario < Sequel::Model
      include CommonModel
      attr_writer :resource_ids
      many_to_one :project
      many_to_many :resources
      one_to_many :matchers
      one_to_many :jobs

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
        runner = case self.resources_dataset.count
                 when 1
                   SingleRunner.new(self)
                 when 2
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

require File.join(File.dirname(__FILE__), 'scenario', 'runner')
