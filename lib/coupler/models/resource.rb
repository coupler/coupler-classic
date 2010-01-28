module Coupler
  module Models
    class Resource < Sequel::Model
      include CommonModel
      many_to_one :project
      one_to_many :transformations
      many_to_many :scenarios

      def source_database(&block)
        Sequel.connect(source_connection_string, {
          :loggers => [Coupler::Logger.instance],
        }, &block)
      end

      def source_dataset
        source_database do |db|
          ds = db[table_name.to_sym]
          yield ds
        end
      end

      def source_schema
        schema = nil
        source_database { |db| schema = db.schema(table_name) }
        schema
      end

      def local_database(&block)
        Sequel.connect(local_connection_string, {
          :loggers => [Coupler::Logger.instance],
        }, &block)
      end

      def local_dataset
        local_database do |database|
          ds = database[self.slug.to_sym]
          yield ds
        end
      end

      def final_database(&block)
        if transformations_dataset.count == 0
          source_database(&block)
        else
          local_database(&block)
        end
      end

      def final_dataset(&block)
        if transformations_dataset.count == 0
          source_dataset(&block)
        else
          local_dataset(&block)
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
        # create transformers and get result schema
        local_schema = self.source_schema
        transformers = []
        transformations.each do |transformation|
          klass = Transformers[transformation.transformer_name]
          transformers << klass.new(:field_name => transformation.field_name)
          local_schema = transformers[-1].schema(local_schema)
        end

        local_database do |l_db|
          # create intermediate table
          l_db.create_table!(self.slug) do
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

          l_ds = l_db[self.slug.to_sym]

          source_dataset do |s_ds|
            # for progress bar
            self.update(:total => s_ds.count, :completed => 0)

            thread_pool = ThreadPool.new(10)
            s_ds.each do |row|
              thread_pool.execute(row) do |r|
                values = transformers.inject(r) { |x, t| t.transform(x) }
                l_ds.insert(values)
                self.class.filter(:id => self.id).update("completed = completed + 1")
              end
            end
            thread_pool.join

            self.update(:transformed_at => Time.now)
          end
        end
      end

      private
        def source_connection_string
          "jdbc:%s://%s:%d/%s?user=%s&password=%s" % [
            adapter, host, port, database_name, username, password
          ]
        end

        def local_connection_string
          Config.connection_string(self.project.slug, :create_database => true)
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
              source_database do |db|
                db.test_connection
                if !db.tables.include?(self.table_name.to_sym)
                  errors[:table_name] << "is invalid"
                end
              end
            rescue Sequel::DatabaseConnectionError => e
              errors[:base] << "Couldn't connect to the database"
            end
          end
        end
    end
  end
end
