module Coupler
  module Models
    class Connection < Sequel::Model
      include CommonModel

      ADAPTERS = [%w{mysql MySQL}]

      one_to_many :resources

      def database(database_name, &block)
        Sequel.connect(connection_string(database_name), {
          :loggers => [Coupler::Logger.instance],
        }, &block)
      end

      private
        def connection_string(database_name)
          misc = adapter == 'mysql' ? '&zeroDateTimeBehavior=convertToNull' : ''
          "jdbc:%s://%s:%d/%s?user=%s&password=%s%s" % [
            adapter, host, port, database_name, username, password, misc
          ]
        end

        def before_validation
          super
          self.slug ||= name.downcase.gsub(/\s+/, "_") if name
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

          if self.new?
            count = self.class.filter(:slug => self.slug).count
            errors[:slug] << "is already taken"   if count > 0
          else
            count = self.class.filter(["slug = ? AND id != ?", self.slug, self.id]).count
            errors[:slug] << "is already taken"   if count > 0
          end

          begin
            database("") { |db| db.test_connection }
          rescue Sequel::DatabaseConnectionError, Sequel::DatabaseError => e
            errors[:base] << "Couldn't connect to the database"
          end
        end
    end
  end
end
