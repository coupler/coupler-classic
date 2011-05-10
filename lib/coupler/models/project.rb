module Coupler
  module Models
    class Project < Sequel::Model
      include CommonModel
      one_to_many :resources
      one_to_many :scenarios

      def local_database(&block)
        Sequel.connect(local_connection_string, {
          :loggers => [Coupler::Logger.instance],
          :max_connections => 50,
          :pool_timeout => 60
        }, &block)
      end

      private
        def local_connection_string
          Base.connection_string("project_#{id}")
        end

        def before_validation
          super
          self.slug ||= name.downcase.gsub(/\s+/, "_")   if name
        end

        def validate
          super
          validates_presence :name
          validates_unique :name, :slug
        end

        def after_destroy
          super
          FileUtils.rm(Dir[Base.db_path("project_#{id}")+".*"], :force => true)
          resources_dataset.each { |r| r.delete_versions_on_destroy = self.delete_versions_on_destroy; r.destroy }
          scenarios_dataset.each { |s| s.delete_versions_on_destroy = self.delete_versions_on_destroy; s.destroy }
        end
    end
  end
end
