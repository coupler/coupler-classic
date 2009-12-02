module Coupler
  module Models
    class Resource < Sequel::Model
      include CommonModel
      many_to_one :project
      one_to_many :transformations
      one_to_many :jobs

      def connection
        unless @connection
          connection_string = "jdbc:%s://%s:%d/%s?user=%s&password=%s" % [
            adapter, host, port, database_name, username, password
          ]
          @connection = Sequel.connect(connection_string, :loggers => [Coupler.logger])
        end
        @connection
      end

      def dataset
        @dataset ||= connection[table_name.to_sym]
      end

      def result_connection
        unless @result_connection
          connection_string = Server.instance.connection_string(self.project.slug, :create_database => true)
          @result_connection = Sequel.connect(connection_string, :loggers => [Coupler.logger])
        end
        @result_connection
      end

      def schema
        connection.schema(table_name)
      end

      def transform!
        Thread.new { do_transform }
      end

      private
        def process_row(row)
          values = @transformers.inject(row) { |row, t| t.transform(row) }
          @result_dataset.insert(values)
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

          obj = self.class[:slug => self.slug]
          if self.new?
            errors[:slug] << "is already taken"   if obj
          else
            errors[:slug] << "is already taken"   if obj.id != self.id
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

        def before_save
          super
          self.slug ||= self.name.downcase.gsub(/\s+/, "_")
        end

        def do_transform
          # create transformers and get result schema
          result_schema = self.schema
          @transformers = []
          transformations.each do |transformation|
            klass = Transformers[transformation.transformer_name]
            @transformers << klass.new(:field_name => transformation.field_name)
            result_schema = @transformers[-1].schema(result_schema)
          end

          result_connection.create_table!(self.slug) do
            result_schema.each do |(name, info)|
              options = info.dup
              options[:type] = options.delete(:db_type)
              options[:name] = name
              if options[:primary_key]
                options.delete(:default)  unless options[:default]
              end
              columns << options
            end
          end
          @result_dataset = result_connection[self.slug.to_sym]

          thread_pool = ThreadPool.new(10)
          dataset.each do |row|
            thread_pool.execute(row) { |local| process_row(row) }
          end
          thread_pool.join

          self.transformed_at = Time.now
          self.save
        end
    end
  end
end
