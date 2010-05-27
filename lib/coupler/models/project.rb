module Coupler
  module Models
    class Project < Sequel::Model
      include CommonModel
      one_to_many :resources
      one_to_many :scenarios

      def local_database(&block)
        Sequel.connect(local_connection_string, {
          :loggers => [Coupler::Logger.instance],
        }, &block)
      end

      private
        def local_connection_string
          Config.connection_string(:"project_#{id}", {
            :create_database => true,
            :zero_date_time_behavior => :convert_to_null
          })
        end

        def before_validation
          super
          self.slug ||= name.downcase.gsub(/\s+/, "_")   if name
        end

        def validate
          errors[:name] << "is required"  if name.nil? || name == ""

          obj = self.class[:slug => slug]
          if self.new?
            errors[:slug] << "is already taken"   if obj
          else
            errors[:slug] << "is already taken"   if obj.id != id
          end
        end

        def after_destroy
          super
          Sequel.connect(Config.connection_string("information_schema")) do |db|
            db.run("DROP DATABASE IF EXISTS project_#{id}")
          end
          resources_dataset.each { |r| r.delete_versions_on_destroy = self.delete_versions_on_destroy; r.destroy }
          scenarios_dataset.each { |s| s.delete_versions_on_destroy = self.delete_versions_on_destroy; s.destroy }
        end
    end
  end
end
