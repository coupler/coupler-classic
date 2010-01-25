module Coupler
  module Models
    class Resource < Sequel::Model
      include CommonModel
      many_to_one :project
      one_to_many :transformations
      many_to_many :scenarios

      def source_connection
        unless @source_connection
          connection_string = "jdbc:%s://%s:%d/%s?user=%s&password=%s" % [
            adapter, host, port, database_name, username, password
          ]
          @source_connection = Sequel.connect(connection_string, :loggers => [Coupler::Logger.instance], :max_connections => 10)
        end
        @source_connection
      end

      def source_dataset
        @source_dataset ||= source_connection[table_name.to_sym]
      end

      def source_schema
        source_connection.schema(table_name)
      end

      def local_connection
        unless @local_connection
          connection_string = Config.connection_string(self.project.slug, :create_database => true)
          @local_connection = Sequel.connect(connection_string, :loggers => [Coupler::Logger.instance])
        end
        @local_connection
      end

      def local_dataset
        unless @local_dataset
          local_schema = self.source_schema
          transformers.each do |transformer|
            local_schema = transformer.schema(local_schema)
          end

          local_connection.create_table!(self.slug) do
            local_schema.each do |(name, info)|
              options = info.dup
              options[:type] = options.delete(:db_type)
              options[:name] = name
              if options[:primary_key]
                options.delete(:default)  unless options[:default]
              end
              columns << options
            end
          end
          @local_dataset = local_connection[self.slug.to_sym]
        end
        @local_dataset
      end

      def final_connection
        if transformations_dataset.count == 0
          source_connection
        else
          local_connection
        end
      end

      def final_dataset
        if transformations_dataset.count == 0
          source_dataset
        else
          local_dataset
        end
      end

      def status
        if transformed_at.nil?
          if transformations_dataset.count > 0
            "out_of_date"
          else
            "ok"
          end
        else
          if transformations_dataset.filter("updated_at > ?", self.transformed_at).count > 0
            "out_of_date"
          else
            "ok"
          end
        end
      end

      def transform!
        do_transform
      end

      private
        def transformers
          @transformers ||= transformations.collect do |transformation|
            klass = Transformers[transformation.transformer_name]
            klass.new(:field_name => transformation.field_name)
          end
        end

        def process_row(row)
          values = @transformers.inject(row) { |row, t| t.transform(row) }
          @local_dataset.insert(values)
        end

        def before_create
          super
          self.slug ||= self.name.downcase.gsub(/\s+/, "_")
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
              source_connection.test_connection
              if !source_connection.tables.include?(self.table_name.to_sym)
                errors[:table_name] << "is invalid"
              end
            rescue Sequel::DatabaseConnectionError => e
              errors[:base] << "Couldn't connect to the database"
            end
          end
        end

        def do_transform
          # create transformers and get result schema
          local_schema = self.source_schema
          @transformers = []
          transformations.each do |transformation|
            klass = Transformers[transformation.transformer_name]
            @transformers << klass.new(:field_name => transformation.field_name)
            local_schema = @transformers[-1].schema(local_schema)
          end

          local_connection.create_table!(self.slug) do
            local_schema.each do |(name, info)|
              options = info.dup
              options[:type] = options.delete(:db_type)
              options[:name] = name
              if options[:primary_key]
                options.delete(:default)  unless options[:default]
              end
              columns << options
            end
          end
          @local_dataset = local_connection[self.slug.to_sym]

          thread_pool = ThreadPool.new(10)
          source_dataset.each do |row|
            thread_pool.execute(row) { |r| process_row(r) }
          end
          thread_pool.join

          self.transformed_at = Time.now
          self.save
        end
    end
  end
end
