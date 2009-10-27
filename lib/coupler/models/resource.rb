module Coupler
  module Models
    class Resource < Sequel::Model
      include CommonModel
      many_to_one :project
      one_to_many :transformations

      def connection
        connection_string = "jdbc:%s://%s:%d/%s?user=%s&password=%s" % [
          adapter, host, port, database_name, username, password
        ]
        @connection ||= Sequel.connect(connection_string)
      end

      def dataset
        @dataset ||= connection[table_name]
      end

      def schema
        connection.schema(table_name)
      end

      private
        def validate
          if self.name.nil? || self.name == ""
            errors[:name] << "is required"
          else
            obj = self.class[:name => name]
            if self.new?
              errors[:name] << "is already taken"   if obj
            end
          end

          try_connect = true
          [:database_name, :table_name].each do |name|
            value = self.send(name)
            if value.nil? || value == ""
              try_connect = false
              errors[name] << "is required"
            end
          end

          if try_connect
            begin
              connection.test_connection
              if !connection.tables.include?(self.table_name.to_sym)
                errors[:table_name] << "is invalid"
              end
            rescue Sequel::DatabaseConnectionError => e
              errors[:base] << "Couldn't connect to the database"
            end
          end
        end
    end
  end
end
