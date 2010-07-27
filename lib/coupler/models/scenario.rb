module Coupler
  module Models
    class Scenario < Sequel::Model
      include CommonModel
      include Jobify

      attr_writer :resource_ids
      many_to_one :project
      many_to_one :resource_1, :class => "Coupler::Models::Resource"
      many_to_one :resource_2, :class => "Coupler::Models::Resource"
      one_to_many :matchers
      one_to_many :results

      def status
        if matchers_dataset.count == 0
          "no_matchers"
        elsif resource_1.status == "out_of_date" ||
            (resource_2 && resource_2.status == "out_of_date")
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
        runner = case linkage_type
                 when "self-linkage"
                   SingleRunner.new(self)
                 when "dual-linkage"
                   DualRunner.new(self)
                 end

        result = Result.new(:scenario => self)
        types = resources.values_at(0, -1).collect(&:primary_key_type)
        ScoreSet.create(*types) do |score_set|
          result[:score_set_id] = score_set.id
          runner.run(score_set)
        end
        result.save

        update(:last_run_at => Time.now)
      end

      private
        def before_validation
          super
          if @resource_ids.is_a?(Array)
            objects = project.resources_dataset.filter(:id => @resource_ids[0..1].compact).all
            self.resource_1_id = objects[0].nil? ? nil : objects[0].id
            self.resource_2_id = objects[1].nil? ? nil : objects[1].id
          end
        end

        def before_create
          super
          self.slug ||= name.downcase.gsub(/\s+/, "_")
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
          if name.nil? || name == ""
            errors[:name] << "is required"
          else
            if new?
              count = self.class.filter(:name => name).count
              errors[:name] << "is already taken"   if count > 0
            else
              count = self.class.filter(["name = ? AND id != ?", name, id]).count
              errors[:name] << "is already taken"   if count > 0
            end
          end

          if resource_1_id.nil?
            errors[:base] << "At least one resource is required"
          end
        end
    end
  end
end

require File.join(File.dirname(__FILE__), 'scenario', 'runner')
