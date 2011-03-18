module Coupler
  module Models
    class Connection < Sequel::Model
      include CommonModel

      ADAPTERS = [%w{mysql MySQL h2 H2}]

      one_to_many :resources

      def database(database_name = nil, &block)
        Sequel.connect(connection_string(database_name), {
          :loggers => [Coupler::Logger.instance],
          :max_connections => 20
        }, &block)
      end

      def deletable?
        resources_dataset.count == 0
      end

      private
        def connection_string(database_name = nil)
          case adapter
          when 'mysql'
            misc = '&zeroDateTimeBehavior=convertToNull'
            "jdbc:mysql://%s:%d/%s?user=%s&password=%s%s" % [
              host, port, database_name, username, password, misc
            ]
          when 'h2'
            "jdbc:h2:#{path}"
          end
        end

        def before_validation
          super
          self.slug ||= name.downcase.gsub(/\s+/, "_") if name
        end

        def validate
          super
          validates_presence :name
          validates_unique :name, :slug

          begin
            database("") { |db| db.test_connection }
          rescue Sequel::DatabaseConnectionError, Sequel::DatabaseError => e
            errors.add(:base, "Couldn't connect to the database")
          end
        end

        def before_destroy
          super

          # Prevent destruction of connections in use by resources.
          deletable?
        end
    end
  end
end
